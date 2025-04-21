import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  void _launchEmail() async {
    final Uri _emailUri = Uri(
      scheme: 'mailto',
      path: 'sobiaq430@gmail.com',
    );

    try {
      if (await canLaunchUrl(_emailUri)) {
        await launchUrl(_emailUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email app not found',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error launching email: $e');
    }
  }

  bool _showAll = false;
  final List<FAQItem> _faqs = [
    FAQItem(
      question: "How can I place an order?",
      answer: "To place an order, browse the products, add them to your cart, and proceed to checkout. Enter your shipping details, choose a payment method, and confirm your order.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Can I change my delivery address after placing an order?",
      answer: "Yes, you can change the address before the order is shipped. Go to My Orders, select the order, and update the address. Once shipped, changes are not possible.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How do I track my order?",
      answer: "You can track your order in the My Orders section. Click on the order to see the real-time status and tracking details.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What should I do if my order is delayed?",
      answer: "If your order is delayed beyond the estimated delivery date, check the tracking details for updates or contact our customer support.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What payment methods are accepted?",
      answer: "We accept all major credit cards and digital wallets for payment. Cash on Delivery (COD) may also be available for some orders.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Why did my payment fail?",
      answer: "Payment failures can occur due to insufficient balance, incorrect card details, or technical issues. Try again or contact your bank for assistance.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Can I use multiple discount codes on one order?",
      answer: "No, only one discount code can be applied per order. Choose the best available discount before checkout.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What is your return policy?",
      answer: "We accept returns within 7 days of delivery for eligible items. The product must be unused, in original packaging, and with all tags intact.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Can I return an item after using it?",
      answer: "No, used or damaged items are not eligible for return. The product must be in its original condition to qualify.",
      isExpanded: false,
    ),
  ];

  void showHelpDialog(BuildContext context) {
    final String supportEmail = "sobiaq430@gmail.com";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent, size: 60, color: Color(0xFFFF4A49)),
                SizedBox(height: 10),
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Tap below to contact our support team via email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  child: Text(
                    supportEmail,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFFFF4A49),
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _launchEmail,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF4A49),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedFaqs = _showAll ? _faqs : _faqs.sublist(0, 7);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Go back to the previous screen
        ),
      ),

      body: SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Frequently Asked Questions',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Poppins',
    color: Theme.of(context).colorScheme.onBackground,
    ),
    ),
    SizedBox(height: 10),
    ...displayedFaqs.map((faq) => Column(
    children: [
    ExpansionTile(
    title: Text(
    faq.question,
    style: TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: 'Poppins',
      fontSize: 15,
    color: Theme.of(context).colorScheme.onSurface,
    ),
    ),
    children: [
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    child: Text(
    faq.answer,
    style: TextStyle(
    fontFamily: 'Poppins',
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    height: 1.5,
    ),
    ),
    ),
    ],
    tilePadding: EdgeInsets.zero,
    iconColor: Theme.of(context).colorScheme.onSurface,
    collapsedIconColor: Theme.of(context).colorScheme.onSurface,
    ),
    Divider(
    height: 1,
    thickness: 2,
    color: Colors.grey[300],
    ),
    ],
    )).toList(),
    if (_faqs.length > 7)
    Center(
    child: TextButton(
    onPressed: () {
    setState(() {
    _showAll = !_showAll;
    });
    },
    child: Text(
    _showAll ? 'SHOW LESS' : 'VIEW ALL ',
    style: TextStyle(
    color: Color(0xFFFF4A49),
    fontWeight: FontWeight.w600,
    fontSize: 14,
    fontFamily: 'Poppins',
    ),
    ),
    ),
    ),
    SizedBox(height: 10),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Center(
    child: Text(
    'Still stuck? Help us a small check',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    fontFamily: 'Poppins',
    color: Theme.of(context).colorScheme.onBackground,
    ),
    ),
    ),
    SizedBox(height: 12),
    SizedBox(width: double.infinity),
    ElevatedButton.icon(
    onPressed: () => showHelpDialog(context),
    icon: Icon(Icons.mail_outline, size: 20, color: Colors.white),
    label: Text(
    'Send a message',
    style: TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    ),
    ),
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFFF4A49),
    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(25),
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
  });
}