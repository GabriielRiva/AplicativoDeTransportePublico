import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums/user_role.dart';

/// Seletor de perfil Motorista/Passageiro da tela de cadastro (RF01).
class ProfileSelector extends StatelessWidget {
  /// Cria o seletor com o perfil [selected] destacado.
  const ProfileSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Perfil atualmente selecionado.
  final UserRole selected;

  /// Callback de troca de perfil.
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ProfileOption(
            role: UserRole.driver,
            icon: Icons.directions_bus_filled,
            isSelected: selected == UserRole.driver,
            onTap: () => onChanged(UserRole.driver),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileOption(
            role: UserRole.passenger,
            icon: Icons.person_outline,
            isSelected: selected == UserRole.passenger,
            onTap: () => onChanged(UserRole.passenger),
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.role,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? kPrimaryColor : kSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? Colors.white : kTextPrimaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                role.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kTextPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
