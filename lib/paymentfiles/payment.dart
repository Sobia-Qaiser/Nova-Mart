//
// import 'dart:convert';
//
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// Future cretaePaymentIntent({
//   required String name,
//   required String address,
//   required String pin,
//   required String city,
//   required String state,
//   required String country,
//   required String currency,
//   required String amount
// }) async{
//   final url=Uri.parse("https://api.stripe.com/v1/payment_intents");
//   final secretKey=dotenv.env["STRIPE_SECRET_KEY"]!;
//   final body={
//     'amount': amount,
//     'currency': currency.toLowerCase(),
//     'automatic_payment_methods[enabled]': 'true',
//     'description': "Test Donation",
//     'shipping[name]': name,
//     'shipping[address][line1]': address,
//     'shipping[address][postal_code]': pin,
//     'shipping[address][city]': city,
//     'shipping[address][state]': state,
//     'shipping[address][country]': country
//   };
//   final response= await http.post(url,
//       headers: {
//         "Authorization": "Bearer $secretKey",
//         'Content-Type': 'application/x-www-form-urlencoded'
//       },
//       body: body
//   );
//
//   print(body);
//   if(response.statusCode==200){
//     var json=jsonDecode(response.body);
//     print(json);
//     return json;
//   }
//   else{
//     print("error in calling payment intent");
//   }
// }

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> cretaePaymentIntent({
  required String name,
  required String address,
  required String pin,
  required String city,
  required String state,
  required String country,
  required String currency,
  required String phone,
  required String amount,
  required String email,

}) async {
  try {
    final url = Uri.parse("https://api.stripe.com/v1/payment_intents");
    final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;

    // Create a customer first (required for ephemeral key)
    final customerUrl = Uri.parse("https://api.stripe.com/v1/customers");
    final customerResponse = await http.post(
      customerUrl,
      headers: {
        "Authorization": "Bearer $secretKey",
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'name=$name&address[line1]=$address&address[postal_code]=$pin'
          '&address[city]=$city&address[state]=$state&address[country]=$country',
    );

    if (customerResponse.statusCode != 200) {
      throw Exception('Failed to create customer: ${customerResponse.body}');
    }

    final customer = jsonDecode(customerResponse.body);
    final customerId = customer['id'];

    // Create ephemeral key
    final ephemeralKeyUrl = Uri.parse("https://api.stripe.com/v1/ephemeral_keys");
    final ephemeralKeyResponse = await http.post(
      ephemeralKeyUrl,
      headers: {
        "Authorization": "Bearer $secretKey",
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-08-16', // Use latest API version
      },
      body: 'customer=$customerId',
    );

    if (ephemeralKeyResponse.statusCode != 200) {
      throw Exception('Failed to create ephemeral key: ${ephemeralKeyResponse.body}');
    }

    final ephemeralKey = jsonDecode(ephemeralKeyResponse.body);

    // Create payment intent with customer
    final body = {
      'amount': amount,
      'currency': currency.toLowerCase(),
      'customer': customerId,
      'automatic_payment_methods[enabled]': 'true',
      'description': "Order Payment",
    };

    final encodedBody = body.keys.map((key) =>
    '${Uri.encodeComponent(key)}=${Uri.encodeComponent(body[key]!)}'
    ).join('&');

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $secretKey",
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: encodedBody,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'client_secret': jsonResponse['client_secret'],
        'ephemeralKey': ephemeralKey['secret'],
        'customerId': customerId,
      };
    } else {
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  } catch (e) {
    print('Error in createPaymentIntent: $e');
    rethrow;
  }
}