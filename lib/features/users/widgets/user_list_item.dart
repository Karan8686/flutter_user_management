import 'package:flutter/material.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(user.image),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            if (user.phone != null) ...[
              const SizedBox(height: 4),
              Text(user.phone!),
            ],
            if (user.company != null) ...[
              const SizedBox(height: 4),
              Text(user.company!),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
