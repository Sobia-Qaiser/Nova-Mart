import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> banners = [];
  int _currentIndex = 0; // Track the current index of the carousel

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  // Fetch banners from Firebase Realtime Database
  void fetchBanners() async {
    DatabaseReference ref = _database.ref("banners");
    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          banners = data.entries.map((entry) {
            return {
              'key': entry.key, // Store the Firebase key
              'image': entry.value['image'].toString(), // Banner image URL
            };
          }).toList();
        });

        // Print fetched banners to the console
        print("Fetched Banners: $banners");
      } else {
        print("No banners found in the database.");
      }
    }).catchError((error) {
      print("Error fetching banners: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: banners.map((banner) {
            return Builder(
              builder: (context) {
                return Container(
                  width: MediaQuery.of(context).size.width, // Full width of the screen
                  margin: const EdgeInsets.symmetric(horizontal: 1), // No horizontal margin
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // No rounded corners
                    image: DecorationImage(
                      image: NetworkImage(banner['image']), // Use the image URL from the banner
                      fit: BoxFit.cover, // Ensure the image covers the container
                    ),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 180, // Normal height for the carousel
            aspectRatio: 16 / 9,
            viewportFraction: 1.0, // Full width of the screen
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false, // No enlargement of the center page
            enlargeFactor: 0.0, // No enlargement
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              // Update the current index when the page changes
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 10), // Space between carousel and dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Smooth animation
              width: _currentIndex == entry.key ? 20 : 6, // Wider for active dot
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4), // Rounded corners for stylish look
                color: _currentIndex == entry.key ? Colors.red : Colors.grey.withOpacity(0.5), // Red for active dot, grey for inactive
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}