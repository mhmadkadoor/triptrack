import 'package:flutter/material.dart';

/// A reusable avatar widget that displays a user's profile picture or their initials.
///
/// If [avatarUrl] is provided and valid, it attempts to load the image.
/// If not, it falls back to displaying the initials derived from [displayName].
class UserAvatar extends StatelessWidget {
  /// The public URL of the avatar image. Can be null.
  final String? avatarUrl;

  /// The name used to generate initials if the image is missing or fails to load.
  final String displayName;

  /// The radius of the avatar circle. Defaults to 20.
  final double radius;

  /// Optional custom background color. Defaults to blueGrey[100].
  final Color? backgroundColor;

  /// Optional custom text color for initials. Defaults to blueGrey[800].
  final Color? textColor;

  /// Function to call when the avatar is tapped.
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blueGrey.shade100,
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? NetworkImage(avatarUrl!)
          : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(
              _getInitials(displayName),
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.blueGrey.shade800,
              ),
            )
          : null, // If we have an image, child is null (or loading indicator)
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final single = parts[0];
      if (single.isEmpty) return '?';
      return single[0].toUpperCase();
    }

    final first = parts.first;
    final last = parts.last;
    if (first.isEmpty || last.isEmpty) return '?';

    return '${first[0]}${last[0]}'.toUpperCase();
  }
}
