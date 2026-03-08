import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_theme.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _numberOfSeats = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<EventController>().loadEventDetail(widget.eventId));
  }

  void _showBookingSheet() {
    final event = context.read<EventController>().selectedEvent;
    if (event == null) return;

    // Reset seats to 1 every time we open the sheet
    _numberOfSeats = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('How many seats do you need?'),
                const SizedBox(height: 24),

                // Seat Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCircularButton(
                      icon: Icons.remove,
                      onTap: _numberOfSeats > 1
                          ? () => setModalState(() => _numberOfSeats--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            '$_numberOfSeats',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const Text('Seats',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildCircularButton(
                      icon: Icons.add,
                      onTap: _numberOfSeats < event.availableSeats
                          ? () => setModalState(() => _numberOfSeats++)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 16)),
                    Text(
                      '\$${(event.pricePerSeat * _numberOfSeats).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      // Close sheet first
                      Navigator.pop(context);

                      // Trigger Controller
                      final success =
                          await context.read<BookingController>().createBooking(
                                event.id,
                                _numberOfSeats,

                              );
                      print("success====$success");
                      if (success && mounted) {
                        _showSuccessSnackBar();
                      }
                    },
                    child: const Text('Confirm Booking',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper for Circular Buttons
  Widget _buildCircularButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color:
          onTap == null ? Colors.grey[200] : AppColors.primary.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon,
              color: onTap == null ? Colors.grey : AppColors.primary),
        ),
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Booking request sent successfully!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Consumer<EventController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = controller.selectedEvent;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 120,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.cuisineType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hosted by ${event.hostName ?? "Host"}',
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoCard(event),
                      const SizedBox(height: 24),
                      const Text(
                        'About',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Menu',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.menuDescription,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      if (context
                                  .watch<AuthController>()
                                  .currentUser
                                  ?.isDiner ==
                              true &&
                          event.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showBookingSheet,
                            child: const Text('Book Now',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
                Icons.calendar_today,
                'Date',
                DateFormat('EEEE, MMM dd, yyyy')
                    .format(DateTime.parse(event.eventDate))),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.access_time,
                'Time',
                DateFormat('hh:mm a')
                    .format(DateFormat('HH:mm:ss').parse(event.eventTime))),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, 'Location', event.location),
            const Divider(height: 24),
            _buildInfoRow(Icons.event_seat, 'Availability', '${event.availableSeats} seats left (${event.totalSeats} total)'),

            const Divider(height: 24),
            _buildInfoRow(Icons.attach_money, 'Price',
                '\$${event.pricePerSeat.toStringAsFixed(2)} per seat'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
