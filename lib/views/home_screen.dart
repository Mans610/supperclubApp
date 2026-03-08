import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../models/event.dart';
import '../widgets/app_theme.dart';
import '../widgets/responsive.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';
import 'bookings_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthController>().loadUserFromStorage();
      context.read<EventController>().loadEvents();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<EventController>().loadMoreEvents();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isHost = auth.currentUser?.isHost ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Supper Club'),
            const SizedBox(width: 12),
            _buildRoleBadge(isHost),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<EventController>().loadEvents(),
              child: Responsive(
                mobile: _buildContent(isHost),
                desktop: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: _buildContent(isHost),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isHost
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Host Dinner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      )
          : null,
    );
  }

  Widget _buildFilterSection() {
    return Consumer<EventController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Cuisine filter
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Cuisine Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: controller.selectedCuisine,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Cuisines')),
                        ...controller.cuisineTypes.map((cuisine) {
                          return DropdownMenuItem(
                            value: cuisine,
                            child: Text(cuisine),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        controller.applyFilters(cuisine: value);
                      },
                    ),
                  ),
                  // City filter
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: controller.selectedCity != null
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            controller.applyFilters(city: null);
                          },
                        )
                            : null,
                      ),
                      onSubmitted: (value) {
                        controller.applyFilters(city: value.isEmpty ? null : value);
                      },
                    ),
                  ),
                  // Clear filters button
                  if (controller.selectedCuisine != null || controller.selectedCity != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.clearFilters();
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: AppColors.textDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHost
              ? [AppColors.primary, AppColors.secondary]
              : [Colors.teal, Colors.tealAccent.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isHost ? AppColors.primary : Colors.teal).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHost ? Icons.restaurant : Icons.person,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isHost ? 'Host' : 'Guest',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isHost) {
    return Consumer<EventController>(
      builder: (context, controller, _) {
        if (controller.isLoading &&
            controller.myEvents.isEmpty &&
            controller.otherEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // My Events Section
            if (controller.upcomingMyEvents.isNotEmpty)
              _buildSection(
                title: isHost ? 'My Hosted Events' : 'My Bookings',
                icon: isHost ? Icons.restaurant_menu : Icons.bookmark,
                events: controller.upcomingMyEvents,
                isPrimary: true,
              ),

            // Past My Events
            if (controller.pastMyEvents.isNotEmpty)
              _buildSection(
                title: isHost ? 'Past Hosted Events' : 'Past Bookings',
                icon: Icons.history,
                events: controller.pastMyEvents,
                isPrimary: true,
                isPast: true,
              ),

            // Other Events Section
            if (controller.upcomingOtherEvents.isNotEmpty)
              _buildSection(
                title: isHost ? 'Other Events' : 'Discover Events',
                icon: Icons.explore,
                events: controller.upcomingOtherEvents,
                isPrimary: false,
              ),

            // Past Other Events
            if (controller.pastOtherEvents.isNotEmpty)
              _buildSection(
                title: 'Past Events',
                icon: Icons.event_busy,
                events: controller.pastOtherEvents,
                isPrimary: false,
                isPast: true,
              ),

            // Empty state
            if (controller.myEvents.isEmpty && controller.otherEvents.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator for pagination
            if (controller.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Event> events,
    required bool isPrimary,
    bool isPast = false,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? AppColors.primary : Colors.grey[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPast ? Colors.grey[600] : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? AppColors.primary : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _buildEventListItem(events[index], isPast);
              },
              childCount: events.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventListItem(Event event, bool isPast) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: isPast ? 1 : 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        child: Opacity(
          opacity: isPast ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image/Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPast
                          ? [Colors.grey[400]!, Colors.grey[600]!]
                          : [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      if (isPast)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PAST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (!event.isAvailable && !isPast)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FULL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (event.isToday && !isPast)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cuisine badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.grey[300]
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.cuisineType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[700] : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey[600] : AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Host name
                      if (event.hostName != null)
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: isPast ? Colors.grey[500] : AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'by ${event.hostName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast ? Colors.grey[500] : AppColors.textLight,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: isPast ? Colors.grey[500] : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast ? Colors.grey[500] : AppColors.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Date and time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isPast ? Colors.grey[500] : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(
                              DateTime.parse(event.eventDate),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast ? Colors.grey[500] : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isPast ? Colors.grey[500] : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.eventTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast ? Colors.grey[500] : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price and seats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${event.totalSeats - event.availableSeats}/${event.totalSeats} seats',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isPast ? Colors.grey[500] : AppColors.textLight,
                            ),
                          ),
                          Text(
                            '\$${event.pricePerSeat.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPast ? Colors.grey[600] : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}