import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../tv/tv_sidebar.dart';
import '../tv/tv_card.dart';
import '../tv/tv_focusable.dart';
import 'live_player_screen.dart';
import 'parental_pin_dialog.dart';
import 'account_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TvNavDestination _currentDestination = TvNavDestination.liveTv;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChannelTap(ChannelItem channel) async {
    final appState = context.read<AppState>();

    // Check if category or channel is locked
    if (appState.isCategoryLocked(channel.categoryId, channel.categoryName ?? '')) {
      final unlocked = await ParentalPinDialog.show(
        context,
        title: 'Parental Lock: ${channel.name}',
        onVerify: (pin) => appState.storageService.verifyPin(pin),
      );
      if (!unlocked) return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LivePlayerScreen(
          initialChannel: channel,
          channelList: appState.filteredChannels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Row(
        children: [
          // 1. TV Navigation Sidebar
          TvSidebar(
            currentDestination: _currentDestination,
            onDestinationSelected: (dest) {
              setState(() => _currentDestination = dest);
            },
          ),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header (Search & Info)
                _buildHeader(appState),

                // Content View
                Expanded(
                  child: _buildMainBody(appState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Text(
            _getSectionTitle(_currentDestination),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),

          // Search Field
          Container(
            width: 260,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2230),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: appState.setSearchQuery,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                hintText: 'Search channels, movies...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Switch / Log out account
          TvFocusable(
            onSelect: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AccountSetupScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text('Accounts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionTitle(TvNavDestination dest) {
    switch (dest) {
      case TvNavDestination.liveTv:
        return 'Live TV Channels';
      case TvNavDestination.movies:
        return 'Movies (VOD)';
      case TvNavDestination.series:
        return 'TV Series';
      case TvNavDestination.favorites:
        return 'Favorite Channels';
      case TvNavDestination.recordings:
        return 'DVR Recordings';
      case TvNavDestination.categoryManager:
        return 'Category & Privacy Manager';
      case TvNavDestination.settings:
        return 'Settings & Parental Control';
    }
  }

  Widget _buildMainBody(AppState appState) {
    if (appState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }

    switch (_currentDestination) {
      case TvNavDestination.liveTv:
        return _buildLiveTvView(appState);
      case TvNavDestination.movies:
        return _buildMoviesView(appState);
      case TvNavDestination.series:
        return _buildEmptyPlaceholder('Series feature syncing with XC API...');
      case TvNavDestination.favorites:
        return _buildFavoritesView(appState);
      case TvNavDestination.recordings:
        return _buildRecordingsView(appState);
      case TvNavDestination.categoryManager:
        return _buildCategoryManagerView(appState);
      case TvNavDestination.settings:
        return _buildSettingsView(appState);
    }
  }

  Widget _buildLiveTvView(AppState appState) {
    final categories = appState.visibleLiveCategories;
    final channels = appState.filteredChannels;

    return Column(
      children: [
        // Category horizontal scroll row
        if (categories.isNotEmpty)
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = appState.selectedLiveCategoryId == 'all' ||
                      appState.selectedLiveCategoryId == null;
                  return _buildCategoryChip('All Channels', isSelected, () {
                    appState.selectLiveCategory('all');
                  });
                }
                final cat = categories[index - 1];
                final isSelected = appState.selectedLiveCategoryId == cat.id;
                return _buildCategoryChip(cat.name, isSelected, () {
                  appState.selectLiveCategory(cat.id);
                });
              },
            ),
          ),

        // Channel Grid
        Expanded(
          child: channels.isEmpty
              ? _buildEmptyPlaceholder('No channels found in this category')
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final ch = channels[index];
                    return TvChannelCard(
                      title: ch.name,
                      number: ch.num,
                      iconUrl: ch.streamIcon,
                      subtitle: ch.categoryName,
                      isFavorite: appState.storageService.isFavorite(ch.id),
                      isLocked: appState.isCategoryLocked(ch.categoryId, ch.categoryName ?? ''),
                      onSelect: () => _onChannelTap(ch),
                      onToggleFavorite: () => appState.toggleFavorite(ch),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMoviesView(AppState appState) {
    final movies = appState.filteredMovies;

    return movies.isEmpty
        ? _buildEmptyPlaceholder('No movies available')
        : GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return TvPosterCard(
                title: movie.name,
                posterUrl: movie.streamIcon,
                rating: movie.rating,
                progress: movie.watchProgress,
                onSelect: () {
                  // Launch VOD player
                },
              );
            },
          );
  }

  Widget _buildFavoritesView(AppState appState) {
    final favs = appState.favoriteChannels;
    return favs.isEmpty
        ? _buildEmptyPlaceholder('No favorite channels yet. Press star to add!')
        : GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.8,
            ),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final ch = favs[index];
              return TvChannelCard(
                title: ch.name,
                number: ch.num,
                iconUrl: ch.streamIcon,
                subtitle: ch.categoryName,
                isFavorite: true,
                onSelect: () => _onChannelTap(ch),
              );
            },
          );
  }

  Widget _buildRecordingsView(AppState appState) {
    final tasks = appState.recordingService.tasks;
    return tasks.isEmpty
        ? _buildEmptyPlaceholder('No stream recordings found.\nPress RECORD while watching any live channel!')
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final mb = (task.totalBytes / (1024 * 1024)).toStringAsFixed(1);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2230),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      task.isActive ? Icons.fiber_manual_record_rounded : Icons.video_file_rounded,
                      color: task.isActive ? Colors.redAccent : const Color(0xFF00E5FF),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.channelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: $mb MB  |  Status: ${task.isActive ? "Recording..." : "Saved"}',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TvFocusable(
                      onSelect: () => appState.recordingService.deleteRecording(task.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildCategoryManagerView(AppState appState) {
    final categories = appState.liveCategories;
    final hiddenCats = appState.storageService.getHiddenCategories();
    final lockedCats = appState.storageService.getLockedCategories();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isHidden = hiddenCats.contains(cat.id);
        final isLocked = lockedCats.contains(cat.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Text(
                cat.name,
                style: TextStyle(
                  color: isHidden ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),

              // Hide/Unhide Toggle
              TvFocusable(
                onSelect: () => appState.toggleCategoryVisibility(cat.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.white12 : const Color(0xFF00E5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 16,
                        color: isHidden ? Colors.white38 : const Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isHidden ? 'Hidden' : 'Visible',
                        style: TextStyle(
                          color: isHidden ? Colors.white38 : const Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // PIN Lock Toggle
              TvFocusable(
                onSelect: () => appState.toggleCategoryLock(cat.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.amber.withOpacity(0.2) : Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 16,
                        color: isLocked ? Colors.amber : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLocked ? 'Locked' : 'Unlocked',
                        style: TextStyle(
                          color: isLocked ? Colors.amber : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsView(AppState appState) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text(
          'Parental Control & Security',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set / Change Security PIN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Protects locked categories and adult channels with a 4-digit code',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              TvFocusable(
                onSelect: () async {
                  await ParentalPinDialog.show(
                    context,
                    title: 'Set New 4-Digit PIN',
                    isSettingPin: true,
                    onVerify: (pin) {
                      appState.storageService.setParentalPin(pin);
                      return true;
                    },
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Configure PIN',
                      style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title, bool isSelected, VoidCallback onSelect) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TvFocusable(
        onSelect: onSelect,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, color: Colors.white24, size: 54),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
