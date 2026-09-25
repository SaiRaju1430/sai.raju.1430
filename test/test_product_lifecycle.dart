// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campuskart/models/product_model.dart';

void main() {
  test('Complete Product Lifecycle: Normal & Offer Products, Add, Stream, Update, Delete', () async {
    const url = 'https://yelczpeowtvhosvwhzxf.supabase.co';
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllbGN6cGVvd3R2aG9zdndoenhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNTkyNDEsImV4cCI6MjEwMzczNTI0MX0.p5BRWVDNvAk-Cy6uqTDEY6GxSM5QBV5_qOLiRWreE5E';

    final supabase = SupabaseClient(url, anonKey);
    final authRes = await supabase.auth.signInWithPassword(
      email: '9515639193@campuskart.com',
      password: 'sai@2007',
    );
    expect(authRes.user, isNotNull);

    // Test 1: Add a Normal Product
    final normalDesc = ProductModel.encodeDescriptionWithOffer('Fresh juicy local apples', isOffer: false);
    final normalInsert = await supabase.from('products').insert({
      'name': 'Lifecycle Test Normal Apple',
      'category': 'Fruits',
      'price': 100.0,
      'quantity': 25,
      'image_url': 'assets/demo_products/carrot.png',
      'description': normalDesc,
      'unit': 'kg',
      'available': true,
    }).select().single();

    final normalId = normalInsert['id'].toString();
    final normalModel = ProductModel.fromMap(normalInsert, normalId);
    expect(normalModel.name, equals('Lifecycle Test Normal Apple'));
    expect(normalModel.description, equals('Fresh juicy local apples'));
    expect(normalModel.isOffer, isFalse);
    expect(normalModel.offerPrice, isNull);
    expect(normalModel.effectivePrice, equals(100.0));
    expect(normalModel.hasDiscount, isFalse);

    // Test 2: Add an Offer Product
    final offerDesc = ProductModel.encodeDescriptionWithOffer(
      'Special discounted bananas for students',
      isOffer: true,
      offerLabel: 'HOT DEAL',
      offerPrice: 35.0,
    );
    final offerInsert = await supabase.from('products').insert({
      'name': 'Lifecycle Test Offer Banana',
      'category': 'Fruits',
      'price': 50.0,
      'quantity': 30,
      'image_url': 'assets/demo_products/banana.png',
      'description': offerDesc,
      'unit': 'kg',
      'available': true,
    }).select().single();

    final offerId = offerInsert['id'].toString();
    final offerModel = ProductModel.fromMap(offerInsert, offerId);
    expect(offerModel.name, equals('Lifecycle Test Offer Banana'));
    expect(offerModel.description, equals('Special discounted bananas for students'));
    expect(offerModel.isOffer, isTrue);
    expect(offerModel.offerLabel, equals('HOT DEAL'));
    expect(offerModel.offerPrice, equals(35.0));
    expect(offerModel.effectivePrice, equals(35.0));
    expect(offerModel.hasDiscount, isTrue);
    expect(offerModel.discountPercentage, equals(30));

    // Test 3: Update Normal Product to become an Offer Product
    final updatedDesc = ProductModel.encodeDescriptionWithOffer(
      'Fresh juicy local apples now on clearance',
      isOffer: true,
      offerLabel: '50% OFF',
      offerPrice: 50.0,
    );
    await supabase.from('products').update({
      'name': 'Lifecycle Test Normal Apple (Discounted)',
      'price': 100.0,
      'quantity': 20,
      'description': updatedDesc,
    }).eq('id', normalId);

    final updatedFetch = await supabase.from('products').select().eq('id', normalId).single();
    final updatedModel = ProductModel.fromMap(updatedFetch, normalId);
    expect(updatedModel.isOffer, isTrue);
    expect(updatedModel.offerLabel, equals('50% OFF'));
    expect(updatedModel.offerPrice, equals(50.0));
    expect(updatedModel.effectivePrice, equals(50.0));

    // Test 4: Delete both products
    await supabase.from('products').delete().eq('id', normalId);
    await supabase.from('products').delete().eq('id', offerId);

    final checkNormal = await supabase.from('products').select().eq('id', normalId).maybeSingle();
    final checkOffer = await supabase.from('products').select().eq('id', offerId).maybeSingle();
    expect(checkNormal, isNull);
    expect(checkOffer, isNull);

    print('All lifecycle tests PASSED successfully!');
  });
}
