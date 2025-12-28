import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriends();
  }

  void _loadFriends() {
    final auth = context.read<AuthService>();
    if (auth.currentUser != null) {
      context.read<FriendService>().loadFriends(auth.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (service.friends.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('No friends yet', style: TextStyle(color: AppColors.textSecondary)),
                Text('Search for players to add!', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: service.friends.length,
          itemBuilder: (context, i) {
            final friend = service.friends[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent,
                child: Text(friend.username[0].toUpperCase()),
              ),
              title: Text(friend.username),
              subtitle: Text('Rating: ${friend.rating}'),
              trailing: PopupMenuButton(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'challenge', child: Text('Challenge')),
                  const PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    final auth = context.read<AuthService>();
                    service.removeFriend(auth.currentUser!.uid, friend.uid);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Consumer<FriendService>(
      builder: (context, service, _) {
        if (service.friendRequests.isEmpty) {
          return const Center(
            child: Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        
        return ListView.builder(
          itemCount: service.friendRequests.length,
          itemBuilder: (context, i) {
            final request = service.friendRequests[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(request.username[0].toUpperCase()),
              ),
              title: Text(request.username),
              subtitle: Text('Rating: ${request.rating}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.accent),
                    onPressed: () {
                      final auth = context.read<AuthService>();
                      service.acceptFriendRequest(auth.currentUser!.uid, request.uid);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      final auth = context.read<AuthService>();
                      service.declineFriendRequest(auth.currentUser!.uid, request.uid);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<FriendService>().searchUsers('', '');
                },
              ),
            ),
            onChanged: (value) {
              final auth = context.read<AuthService>();
              context.read<FriendService>().searchUsers(value, auth.currentUser?.uid ?? '');
            },
          ),
        ),
        Expanded(
          child: Consumer<FriendService>(
            builder: (context, service, _) {
              if (service.searchResults.isEmpty) {
                return const Center(
                  child: Text('Search for players', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              
              return ListView.builder(
                itemCount: service.searchResults.length,
                itemBuilder: (context, i) {
                  final user = service.searchResults[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(user.username[0].toUpperCase()),
                    ),
                    title: Text(user.username),
                    subtitle: Text('Rating: ${user.rating}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add, color: AppColors.accent),
                      onPressed: () {
                        final auth = context.read<AuthService>();
                        service.sendFriendRequest(auth.currentUser!.uid, user.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent!')),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
