import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

IconData categoryIcon(String iconName) {
  return switch (iconName) {
    'restaurant'     => LucideIcons.utensils,
    'directions_car' => LucideIcons.car,
    'school'         => LucideIcons.bookOpen,
    'sports_esports' => LucideIcons.gamepad2,
    'favorite'       => LucideIcons.heartPulse,
    'shopping_bag'   => LucideIcons.shoppingBag,
    'work'           => LucideIcons.briefcase,
    'laptop'         => LucideIcons.laptop,
    'storefront'     => LucideIcons.store,
    'card_giftcard'  => LucideIcons.gift,
    'home'           => LucideIcons.house,
    'flight'         => LucideIcons.plane,
    'movie'          => LucideIcons.clapperboard,
    'fitness_center' => LucideIcons.dumbbell,
    'pets'           => LucideIcons.pawPrint,
    _                => LucideIcons.circleEllipsis,
  };
}