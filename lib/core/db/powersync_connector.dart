import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;

  SupabasePowerSyncConnector(this.db);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final response = await Supabase.instance.client.auth.refreshSession();
    final session = response.session;
    if (session == null) return null;

    final userId = session.user.id;
    if (userId.isEmpty) return null;

    return PowerSyncCredentials(
      endpoint: AppConfig.powerSyncUrl,
      token: session.accessToken,
      expiresAt: session.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
          : null,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final tx = await database.getNextCrudTransaction();
    if (tx == null) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Fields PowerSync tự thêm vào, không có trong Supabase schema
    const excludedFields = {'updated_at'};

    try {
      for (final op in tx.crud) {
        final table = op.table;
        final data = Map<String, dynamic>.from(op.opData ?? {})
          ..removeWhere((k, _) => excludedFields.contains(k));

        switch (op.op) {
          case UpdateType.put:
            await client.from(table).upsert({
              'id': op.id,
              'user_id': userId,
              ...data,
            });
          case UpdateType.patch:
            await client.from(table).update(data).eq('id', op.id);
          case UpdateType.delete:
            await client.from(table).delete().eq('id', op.id);
        }
      }
      await tx.complete();
    } catch (e) {
      await tx.complete();
      rethrow;
    }
  }
}