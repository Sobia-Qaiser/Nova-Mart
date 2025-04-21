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
      question: "How can I check the status of orders received?",
      answer: "Go to Dashboard → Orders to view the status of all customer orders, including pending, shipped, and completed orders.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What happens if a customer cancels an order?",
      answer: "If the order is not shipped, it will be automatically canceled. If shipped, the return policy will apply.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What if a product is delayed in delivery?",
      answer: "Update the customer as soon as possible. If necessary, offer a discount or replacement.",
      isExpanded: false,
    ),
    FAQItem(
      question: "The customer didn’t receive the product. What should I do?",
      answer: "First, check the tracking status. If the product is lost, contact the support team for assistance.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How can I contact support if I have an issue?",
      answer: "Go to Dashboard → Help Center, where you’ll find options for Live Chat or Email Support.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How can I update or edit my product details?",
      answer: "Go to Dashboard → Edits, select the product, make changes, and click Save.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Can I delete a product from my store?",
      answer: "Yes, go to Dashboard → Products, find the product, and click the Delete option.",
      isExpanded: false,
    ),
    FAQItem(
      question: "A customer left a negative review. What should I do?",
      answer: "Politely respond to the review, address their concerns, and offer a solution if possible. Good customer service can improve your reputation.",
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