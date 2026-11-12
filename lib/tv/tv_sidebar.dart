import 'package:flutter/material.dart';
import 'tv_focusable.dart';

enum TvNavDestination {
  liveTv,
  movies,
  series,
  favorites,
  recordings,
  categoryManager,
  settings,
}

class TvSidebar extends StatelessWidget {
  final TvNavDestination currentDestination;
  final ValueChanged<TvNavDestination> onDestinationSelected;

  const TvSidebar({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // VeloxTV Logo Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 32),

          // Navigation items
          _buildNavItem(
            icon: Icons.live_tv_rounded,
            destination: TvNavDestination.liveTv,
            tooltip: 'Live TV',
          ),
          _buildNavItem(
            icon: Icons.movie_rounded,
            destination: TvNavDestination.movies,
            tooltip: 'Movies',
          ),
          _buildNavItem(
            icon: Icons.tv_rounded,
            destination: TvNavDestination.series,
            tooltip: 'Series',
          ),
          _buildNavItem(
            icon: Icons.star_rounded,
            destination: TvNavDestination.favorites,
            tooltip: 'Favorites',
          ),
          _buildNavItem(
            icon: Icons.fiber_manual_record_rounded,
            destination: TvNavDestination.recordings,
            tooltip: 'Recordings',
          ),
          _buildNavItem(
            icon: Icons.dashboard_customize_rounded,
            destination: TvNavDestination.categoryManager,
            tooltip: 'Categories & Privacy',
          ),

          const Spacer(),

          // Settings item at bottom
          _buildNavItem(
            icon: Icons.settings_rounded,
            destination: TvNavDestination.settings,
            tooltip: 'Settings',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required TvNavDestination destination,
    required String tooltip,
  }) {
    final isSelected = currentDestination == destination;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TvFocusable(
        scaleFactor: 1.12,
        borderRadius: BorderRadius.circular(14),
        glowColor: const Color(0xFF00E5FF),
        onSelect: () => onDestinationSelected(destination),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
            size: 24,
          ),
        ),
      ),
    );
  }
}
