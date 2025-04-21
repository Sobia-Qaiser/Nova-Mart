
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {

  Widget rowHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700),
          color: Colors.yellow.shade700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Products',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 20),
            // Horizontal scrollable table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: screenWidth * 1.5, // Adjust width for mobile
                child: Row(
                  children: [
                    rowHeader('Image', 1),
                    rowHeader('Name', 2),
                    rowHeader('Price', 1),
                    rowHeader('Quantity', 1),
                    rowHeader('Action', 1),
                  ],
                ),
              ),
            ),
            // Add more widgets here if needed
          ],
        ),
      ),
    );
  }
}
