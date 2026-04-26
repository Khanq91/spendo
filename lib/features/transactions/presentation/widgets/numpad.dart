import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final Function(String) onKey;

  const Numpad({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _key('1'), _key('2'), _key('3'),
        _key('4'), _key('5'), _key('6'),
        _key('7'), _key('8'), _key('9'),
        _key('00'), _key('0'), _key('⌫', isDelete: true),
      ],
    );
  }

  Widget _key(String label, {bool isDelete = false}) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => onKey(label),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, size: 20)
                : Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}