import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../supabase_options.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/personal_request_model.dart';
import '../../models/fast_food_item_model.dart';
import '../../models/fast_food_order_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  bool get isOfflineMode => false;

  /// Initialize Supabase
  Future<void> initialize() async {
    try {
      // Supabase is already initialized in main(), but check if active
      if (SupabaseOptions.url.isNotEmpty && SupabaseOptions.url != 'YOUR_SUPABASE_PROJECT_URL') {
        try {
          // Verify client is initialized
          final _ = client.auth.currentSession;
          debugPrint("CampusKart: Supabase active and ready (${SupabaseOptions.url}).");
        } catch (_) {
          await Supabase.initialize(
            url: SupabaseOptions.url,
            anonKey: SupabaseOptions.anonKey,
          );
          debugPrint("CampusKart: Supabase initialized successfully.");
        }
      }
    } catch (e) {
      debugPrint("CampusKart: Supabase initialization check: $e");
    }
  }

  Future<bool> testConnection() async {
    try {
      await client.from('profiles').select('id').limit(1).maybeSingle();
      debugPrint("CampusKart Test: Connection test SUCCESS.");
      return true;
    } catch (e) {
      debugPrint("CampusKart Test: Connection test: $e");
      return false;
    }
  }

  // ==========================================
  // --- AUTHENTICATION & PROFILES ---
  // ==========================================

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Attempt native Web Google Sign-In first
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId: SupabaseOptions.webClientId,
            serverClientId: SupabaseOptions.webClientId,
            scopes: ['email', 'openid', 'profile'],
          );

          try {
            await googleSignIn.signOut();
          } catch (_) {}

          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final String? idToken = googleAuth.idToken;
            final String? accessToken = googleAuth.accessToken;

            if (idToken != null) {
              final AuthResponse res = await client.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: idToken,
                accessToken: accessToken,
              );
              return res.user;
            }
          } else {
            // User cancelled picker intentionally
            return null;
          }
        } catch (webErr) {
          debugPrint("CampusKart: Native Web GoogleSignIn error ($webErr). Launching Supabase OAuth redirect...");
        }

        // Web OAuth redirect fallback (100% reliable across all browsers)
        final String currentUrl = Uri.base.origin + (Uri.base.path.isEmpty ? '/' : Uri.base.path);
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: currentUrl,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
        return client.auth.currentUser;
      } else {
        // Mobile platform (Android/iOS)
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: SupabaseOptions.webClientId,
          scopes: ['email', 'openid'],
        );

        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw Exception("Google Sign-In failed: No ID Token received.");
        }

        final AuthResponse res = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        return res.user;
      }
    } catch (e) {
      debugPrint("CampusKart: Google Sign-In error: $e");
      final str = e.toString();
      if (str.contains('People API') || str.contains('people.googleapis.com')) {
        throw Exception("Google People API was recently enabled. Google Cloud takes 2-5 minutes to propagate. Please try again shortly.");
      }
      rethrow;
    }
  }

  Future<UserModel?> checkProfileExists(String uid) async {
    try {
      final response = await client.from('profiles').select().eq('id', uid).maybeSingle();
      if (response != null) {
        return UserModel.fromMap(response, response['id'] ?? '');
      }
      return null;
    } catch (e) {
      debugPrint("CampusKart: checkProfileExists error: $e");
      return null;
    }
  }

  Future<UserModel> completeProfileRegistration({
    required String uid,
    required String name,
    required String mobile,
    required String role,
    String? email,
  }) async {
    final now = DateTime.now().toIso8601String();
    final profileData = {
      'id': uid,
      'name': name,
      'mobile': mobile,
      'role': role,
      'email': email,
      'notifications_enabled': true,
      'updated_at': now,
    };

    try {
      await client.from('profiles').upsert(profileData);
      return UserModel(
        uid: uid,
        name: name,
        mobile: mobile,
        role: role,
        email: email,
        notificationsEnabled: true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint("CampusKart: completeProfileRegistration error: $e");
      rethrow;
    }
  }

  Future<UserModel> register(String name, String mobile, String password, String role) async {
    try {
      final String email = '$mobile@campuskart.com';
      final AuthResponse res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'mobile': mobile,
          'role': role,
        },
      );

      if (res.user == null) {
        throw Exception("Registration failed.");
      }

      final user = UserModel(
        uid: res.user!.id,
        name: name,
        mobile: mobile,
        role: role,
        email: email,
      );

      await client.from('profiles').upsert({
        'id': user.uid,
        'name': user.name,
        'mobile': user.mobile,
        'role': user.role,
        'email': user.email,
        'notifications_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return user;
    } catch (e) {
      debugPrint("CampusKart: register error: $e");
      rethrow;
    }
  }

  Future<UserModel> login(String mobile, String password) async {
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
      final tenDigit = cleanMobile.length > 10 ? cleanMobile.substring(cleanMobile.length - 10) : cleanMobile;
      final String email = '$tenDigit@campuskart.com';
      final bool isCampusAdmin = (tenDigit == '9515639193' && password == 'sai@2007');

      // Auto-register/login admin if predefined credentials match (9515639193 / sai@2007)
      if (isCampusAdmin) {
        try {
          final res = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return await _getOrCreateSupabaseUser(res.user!, tenDigit, 'admin');
        } catch (_) {
          // If login with new password fails, attempt update from old password or signup
          try {
            final oldRes = await client.auth.signInWithPassword(
              email: email,
              password: '123456',
            );
            await client.auth.updateUser(UserAttributes(password: 'sai@2007'));
            return await _getOrCreateSupabaseUser(oldRes.user!, tenDigit, 'admin');
          } catch (_) {
            try {
              final res = await client.auth.signUp(
                email: email,
                password: password,
                data: {
                  'name': 'Campus Admin',
                  'mobile': tenDigit,
                  'role': 'admin',
                },
              );
              return await _getOrCreateSupabaseUser(res.user!, tenDigit, 'admin');
            } catch (registerError) {
              debugPrint("CampusKart: Auto admin registration failed: $registerError");
            }
          }
        }
      }

      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception("Login failed. Invalid credentials.");
      }

      final role = isCampusAdmin ? 'admin' : 'customer';
      return await _getOrCreateSupabaseUser(res.user!, tenDigit, role);
    } catch (e) {
      debugPrint("CampusKart: login error: $e");
      rethrow;
    }
  }

  Future<UserModel> _getOrCreateSupabaseUser(User sbUser, String mobile, String defaultRole) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', sbUser.id)
          .maybeSingle();

      if (response != null) {
        if (defaultRole == 'admin' && response['role'] != 'admin') {
          await client.from('profiles').update({'role': 'admin'}).eq('id', sbUser.id);
          response['role'] = 'admin';
        }
        return UserModel.fromMap(response, response['id'] ?? '');
      }
    } catch (e) {
      debugPrint("CampusKart: Supabase error getting user profile: $e");
    }

    final String name = sbUser.userMetadata?['name'] ?? 
                         sbUser.userMetadata?['full_name'] ?? 
                         (defaultRole == 'admin' ? 'Campus Owner' : 'Student');

    final UserModel user = UserModel(
      uid: sbUser.id,
      name: name,
      mobile: mobile,
      role: defaultRole,
      email: sbUser.email,
    );

    try {
      await client.from('profiles').upsert({
        'id': user.uid,
        'name': user.name,
        'mobile': user.mobile,
        'role': user.role,
        'email': user.email,
        'notifications_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("CampusKart: Supabase error setting user profile: $e");
    }
    return user;
  }

  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseOptions.webClientId,
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint("CampusKart: Logout error: $e");
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final sbUser = client.auth.currentUser;
      if (sbUser == null) return null;

      final response = await client
          .from('profiles')
          .select()
          .eq('id', sbUser.id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromMap(response, response['id'] ?? '');
      }
      return null;
    } catch (e) {
      debugPrint("CampusKart: getCurrentUser error: $e");
      return null;
    }
  }

  // ==========================================
  // --- STORAGE / IMAGE UPLOADS ---
  // ==========================================

  Future<String> uploadImageBytes({
    required String bucketName,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await client.storage.from(bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      debugPrint("CampusKart: Storage upload error ($bucketName/$path): $e");
      rethrow;
    }
  }

  // ==========================================
  // --- PRODUCT MANAGEMENT ---
  // ==========================================

  Stream<List<ProductModel>> streamProducts() {
    return client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((data) => ProductModel.fromMap(data, data['id'] ?? ''))
            .toList());
  }

  Future<String> addProduct(
    String name,
    String category,
    double price,
    int quantity,
    String imageUrl,
    String description,
    String unit,
  ) async {
    final response = await client.from('products').insert({
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'description': description,
      'unit': unit,
      'available': quantity > 0,
    }).select('id').single();
    return response['id'].toString();
  }

  Future<void> updateProduct(ProductModel product) async {
    await client.from('products').update({
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'quantity': product.quantity,
      'image_url': product.imageUrl,
      'description': product.description,
      'unit': product.unit,
      'available': product.quantity > 0,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  // ==========================================
  // --- ORDER MANAGEMENT ---
  // ==========================================

  Stream<List<OrderModel>> streamCustomerOrders(String customerId) {
    final controller = StreamController<List<OrderModel>>();
    
    Future<void> fetchAndAdd() async {
      try {
        final response = await client
            .from('orders')
            .select('*, order_items(*)')
            .eq('customer_id', customerId);
            
        final now = DateTime.now();
        final orders = (response as List)
            .map((data) {
              final mappedData = Map<String, dynamic>.from(data);
              mappedData['items'] = data['order_items'];
              return OrderModel.fromMap(mappedData, data['id'] ?? '');
            })
            .where((order) => order.deleteAfter == null || order.deleteAfter!.isAfter(now))
            .toList();
        
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        if (!controller.isClosed) controller.add(orders);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetchAndAdd();

    final channel = client.channel('public:orders_customer_$customerId')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              final record = payload.newRecord;
              final oldRecord = payload.oldRecord;
              if (record['customer_id'] == customerId || oldRecord['customer_id'] == customerId) {
                fetchAndAdd();
              }
            })
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };
    return controller.stream;
  }

  Stream<List<OrderModel>> streamAllOrders() {
    final controller = StreamController<List<OrderModel>>();
    
    Future<void> fetchAndAdd() async {
      try {
        final response = await client.from('orders').select('*, order_items(*)');
        final now = DateTime.now();
        final orders = (response as List)
            .map((data) {
              final mappedData = Map<String, dynamic>.from(data);
              mappedData['items'] = data['order_items'];
              return OrderModel.fromMap(mappedData, data['id'] ?? '');
            })
            .where((order) => order.deleteAfter == null || order.deleteAfter!.isAfter(now))
            .toList();
        
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        if (!controller.isClosed) controller.add(orders);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetchAndAdd();

    final channel = client.channel('public:orders_all')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (_) => fetchAndAdd())
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };
    return controller.stream;
  }

  Future<String> placeOrder(OrderModel order) async {
    try {
      final code = order.verificationCode.isNotEmpty 
          ? order.verificationCode 
          : (Random().nextInt(9000) + 1000).toString();

      final orderRes = await client.from('orders').insert({
        'customer_id': order.customerId,
        'customer_name': order.customerName,
        'customer_mobile': order.customerMobile,
        'block_name': order.blockName,
        'room_number': order.roomNumber,
        'subtotal': order.subtotal,
        'delivery_fee': order.deliveryFee,
        'total': order.total,
        'payment_id': order.paymentId,
        'payment_account_name': order.paymentAccountName,
        'payment_mobile_number': order.paymentMobileNumber,
        'verification_code': code,
        'status': 'Pending',
        'delivery_verified': false,
      }).select('id').single();
      
      final String newOrderId = orderRes['id'];

      for (var item in order.items) {
        await client.from('order_items').insert({
          'order_id': newOrderId,
          'product_id': item.productId.isNotEmpty ? item.productId : null,
          'product_name': item.productName,
          'quantity': item.quantity,
          'price': item.price,
          'image_url': item.imageUrl,
          'unit': item.unit,
        });

        // Deduct inventory
        if (item.productId.isNotEmpty) {
          try {
            final prodRes = await client.from('products').select('quantity').eq('id', item.productId).single();
            final int currentQty = prodRes['quantity'] ?? 0;
            int newQty = currentQty - item.quantity;
            if (newQty < 0) newQty = 0;
            await client.from('products').update({
              'quantity': newQty,
              'available': newQty > 0,
            }).eq('id', item.productId);
          } catch (e) {
            debugPrint("CampusKart: Failed to deduct product quantity: $e");
          }
        }
      }
      return newOrderId;
    } catch (e) {
      debugPrint("CampusKart: Supabase placeOrder failed: $e");
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final now = DateTime.now();
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    if (status == 'Delivered') {
      updateData['delivery_verified'] = true;
      updateData['delivered_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['rejected_at'] = null;
    } else if (status == 'Rejected') {
      updateData['rejected_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['delivered_at'] = null;
    } else {
      updateData['delete_after'] = null;
      updateData['completed_at'] = null;
    }
    await client.from('orders').update(updateData).eq('id', orderId);
  }

  // ==========================================
  // --- PERSONAL REQUESTS ---
  // ==========================================

  Stream<List<PersonalRequestModel>> streamCustomerRequests(String customerId) {
    return client
        .from('personal_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .map((list) {
          final now = DateTime.now();
          final reqs = list
              .map((data) => PersonalRequestModel.fromMap(data, data['id'] ?? ''))
              .where((req) => req.deleteAfter == null || req.deleteAfter!.isAfter(now))
              .toList();
          reqs.sort((a, b) => b.requestDate.compareTo(a.requestDate));
          return reqs;
        });
  }

  Stream<List<PersonalRequestModel>> streamAllRequests() {
    return client
        .from('personal_requests')
        .stream(primaryKey: ['id'])
        .map((list) {
          final now = DateTime.now();
          final reqs = list
              .map((data) => PersonalRequestModel.fromMap(data, data['id'] ?? ''))
              .where((req) => req.deleteAfter == null || req.deleteAfter!.isAfter(now))
              .toList();
          reqs.sort((a, b) => b.requestDate.compareTo(a.requestDate));
          return reqs;
        });
  }

  Future<void> submitPersonalRequest(PersonalRequestModel request) async {
    final code = request.verificationCode.isNotEmpty 
        ? request.verificationCode 
        : (Random().nextInt(9000) + 1000).toString();

    await client.from('personal_requests').insert({
      'customer_id': request.customerId,
      'customer_name': request.customerName,
      'customer_mobile': request.customerMobile,
      'block_name': request.blockName,
      'room_number': request.roomNumber,
      'description': request.description,
      'image_url': request.imageUrl,
      'product_price': request.productPrice,
      'delivery_charge': request.deliveryCharge,
      'total_amount': request.totalAmount,
      'payment_id': request.paymentId,
      'payment_account_name': request.paymentAccountName,
      'payment_mobile_number': request.paymentMobileNumber,
      'verification_code': code,
      'status': request.status.isNotEmpty ? request.status : 'Pending Review',
      'delivery_verified': false,
    });
  }

  Future<void> updatePersonalRequest(PersonalRequestModel request) async {
    final Map<String, dynamic> updateData = {
      'product_price': request.productPrice,
      'delivery_charge': request.deliveryCharge,
      'total_amount': request.totalAmount,
      'payment_id': request.paymentId,
      'payment_account_name': request.paymentAccountName,
      'payment_mobile_number': request.paymentMobileNumber,
      'verification_code': request.verificationCode,
      'status': request.status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (request.status == 'Delivered') {
      final now = DateTime.now();
      updateData['delivery_verified'] = true;
      updateData['delivered_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
    } else if (request.status == 'Rejected') {
      final now = DateTime.now();
      updateData['rejected_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
    }
    await client.from('personal_requests').update(updateData).eq('id', request.id);
  }

  Future<void> deliverPersonalRequest(String requestId) async {
    final now = DateTime.now();
    await client.from('personal_requests').update({
      'status': 'Delivered',
      'delivery_verified': true,
      'delivered_at': now.toIso8601String(),
      'completed_at': now.toIso8601String(),
      'delete_after': now.add(const Duration(days: 3)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> updatePersonalRequestStatus(String requestId, String status) async {
    final now = DateTime.now();
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    if (status == 'Delivered') {
      updateData['delivery_verified'] = true;
      updateData['delivered_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['rejected_at'] = null;
    } else if (status == 'Rejected') {
      updateData['rejected_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['delivered_at'] = null;
    } else {
      updateData['delete_after'] = null;
      updateData['completed_at'] = null;
    }
    await client.from('personal_requests').update(updateData).eq('id', requestId);
  }

  // ==========================================
  // --- SHOP AVAILABILITY & SETTINGS ---
  // ==========================================

  Stream<bool> streamShopAvailability() {
    return client
        .from('settings')
        .stream(primaryKey: ['id'])
        .eq('id', 'global')
        .map((list) => list.isNotEmpty ? (list.first['owner_available'] ?? true) : true);
  }

  Future<void> toggleShopAvailability(bool available) async {
    await client
        .from('settings')
        .update({
          'owner_available': available,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 'global');
  }

  // ==========================================
  // --- FAST FOOD ITEMS ---
  // ==========================================

  Stream<List<FastFoodItemModel>> streamFastFoodItems() {
    return client
        .from('fast_food_items')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((data) => FastFoodItemModel.fromMap(data, data['id'] ?? ''))
            .toList());
  }

  Future<String> addFastFoodItem(
    String name,
    String description,
    String category,
    double price,
    String imageUrl,
    bool available,
  ) async {
    final response = await client.from('fast_food_items').insert({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'available': available,
    }).select('id').single();
    return response['id'].toString();
  }

  Future<void> updateFastFoodItem(FastFoodItemModel item) async {
    await client.from('fast_food_items').update({
      'name': item.name,
      'description': item.description,
      'category': item.category,
      'price': item.price,
      'image_url': item.imageUrl,
      'available': item.available,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);
  }

  Future<void> deleteFastFoodItem(String id) async {
    await client.from('fast_food_items').delete().eq('id', id);
  }

  // ==========================================
  // --- FAST FOOD ORDERS ---
  // ==========================================

  Stream<List<FastFoodOrderModel>> streamCustomerFastFoodOrders(String customerId) {
    final controller = StreamController<List<FastFoodOrderModel>>();
    
    Future<void> fetchAndAdd() async {
      try {
        final response = await client
            .from('fast_food_orders')
            .select('*, fast_food_order_items(*)')
            .eq('customer_id', customerId);
            
        final now = DateTime.now();
        final orders = (response as List)
            .map((data) {
              final mappedData = Map<String, dynamic>.from(data);
              mappedData['items'] = data['fast_food_order_items'];
              return FastFoodOrderModel.fromMap(mappedData, data['id'] ?? '');
            })
            .where((order) => order.deleteAfter == null || order.deleteAfter!.isAfter(now))
            .toList();
        
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!controller.isClosed) controller.add(orders);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetchAndAdd();

    final channel = client.channel('public:ff_orders_customer_$customerId')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'fast_food_orders',
            callback: (payload) {
              final record = payload.newRecord;
              final oldRecord = payload.oldRecord;
              if (record['customer_id'] == customerId || oldRecord['customer_id'] == customerId) {
                fetchAndAdd();
              }
            })
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };
    return controller.stream;
  }

  Stream<List<FastFoodOrderModel>> streamAllFastFoodOrders() {
    final controller = StreamController<List<FastFoodOrderModel>>();
    
    Future<void> fetchAndAdd() async {
      try {
        final response = await client.from('fast_food_orders').select('*, fast_food_order_items(*)');
        final now = DateTime.now();
        final orders = (response as List)
            .map((data) {
              final mappedData = Map<String, dynamic>.from(data);
              mappedData['items'] = data['fast_food_order_items'];
              return FastFoodOrderModel.fromMap(mappedData, data['id'] ?? '');
            })
            .where((order) => order.deleteAfter == null || order.deleteAfter!.isAfter(now))
            .toList();
        
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!controller.isClosed) controller.add(orders);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetchAndAdd();

    final channel = client.channel('public:ff_orders_all')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'fast_food_orders',
            callback: (_) => fetchAndAdd())
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };
    return controller.stream;
  }

  Future<String> placeFastFoodOrder(FastFoodOrderModel order) async {
    final code = order.deliveryCode.isNotEmpty 
        ? order.deliveryCode 
        : (Random().nextInt(9000) + 1000).toString();

    try {
      final orderRes = await client.from('fast_food_orders').insert({
        'customer_id': order.customerId,
        'customer_name': order.customerName,
        'mobile': order.mobile,
        'block_name': order.blockName,
        'room_number': order.roomNumber,
        'subtotal': order.subtotal,
        'delivery_fee': order.deliveryFee,
        'total_amount': order.totalAmount,
        'payment_id': order.paymentId,
        'status': order.status.isNotEmpty ? order.status : 'Pending',
        'food_total': order.foodTotal,
        'delivery_charge': order.deliveryCharge,
        'cod_charge': order.codCharge,
        'payment_method': order.paymentMethod,
        'grand_total': order.grandTotal,
        'delivery_code': code,
        'delivery_verified': false,
      }).select('id').single();

      final String newOrderId = orderRes['id'];

      for (var item in order.items) {
        await client.from('fast_food_order_items').insert({
          'order_id': newOrderId,
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
        });
      }
      return newOrderId;
    } catch (e) {
      debugPrint("CampusKart: Supabase placeFastFoodOrder failed: $e");
      rethrow;
    }
  }

  Future<String> confirmFastFoodPayment(String orderId) async {
    final doc = await client.from('fast_food_orders').select('delivery_code').eq('id', orderId).single();
    final String code = (doc['delivery_code'] ?? '').toString();
    await client.from('fast_food_orders').update({
      'status': 'Confirmed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    return code;
  }

  Future<void> rejectFastFoodPayment(String orderId) async {
    final now = DateTime.now();
    await client.from('fast_food_orders').update({
      'status': 'Rejected',
      'rejected_at': now.toIso8601String(),
      'completed_at': now.toIso8601String(),
      'delete_after': now.add(const Duration(days: 3)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> updateFastFoodOrderStatus(String orderId, String status) async {
    final now = DateTime.now();
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    if (status == 'Delivered') {
      updateData['delivery_verified'] = true;
      updateData['delivered_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['rejected_at'] = null;
    } else if (status == 'Rejected') {
      updateData['rejected_at'] = now.toIso8601String();
      updateData['completed_at'] = now.toIso8601String();
      updateData['delete_after'] = now.add(const Duration(days: 3)).toIso8601String();
      updateData['delivered_at'] = null;
    } else {
      updateData['delete_after'] = null;
      updateData['completed_at'] = null;
    }
    await client.from('fast_food_orders').update(updateData).eq('id', orderId);
  }

  Future<void> verifyAndDeliverFastFoodOrder(String orderId) async {
    final now = DateTime.now();
    await client.from('fast_food_orders').update({
      'status': 'Delivered',
      'delivery_verified': true,
      'delivered_at': now.toIso8601String(),
      'completed_at': now.toIso8601String(),
      'delete_after': now.add(const Duration(days: 3)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('id', orderId);
  }

  // ==========================================
  // --- BROADCAST MESSAGES ---
  // ==========================================

  Stream<List<Map<String, dynamic>>> streamBroadcasts() {
    return client
        .from('admin_broadcasts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((doc) => {
                  'id': doc['id'],
                  'title': doc['title'],
                  'content': doc['content'],
                  'targetType': doc['target_type'],
                  'targetCustomerId': doc['target_customer_id'],
                  'createdAt': doc['created_at'],
                })
            .toList());
  }

  Future<void> sendBroadcast({
    required String title,
    required String content,
    required String targetType,
    String? targetCustomerId,
  }) async {
    await client.from('admin_broadcasts').insert({
      'title': title,
      'content': content,
      'target_type': targetType,
      'target_customer_id': targetCustomerId,
    });
  }

  // ==========================================
  // --- USER NOTIFICATIONS ---
  // ==========================================

  Future<void> updateUserNotificationSettings(String uid, bool enabled) async {
    await client
        .from('profiles')
        .update({
          'notifications_enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }

  Stream<bool> streamSendNotificationOnNewItem() {
    return client
        .from('settings')
        .stream(primaryKey: ['id'])
        .eq('id', 'global')
        .map((list) => list.isNotEmpty ? (list.first['send_notification_on_new_item'] ?? true) : true);
  }

  Future<void> toggleSendNotificationOnNewItem(bool enabled) async {
    await client
        .from('settings')
        .update({
          'send_notification_on_new_item': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 'global');
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    String? targetUserId,
  }) async {
    List<String> targetUserIds = [];
    if (targetUserId != null) {
      targetUserIds.add(targetUserId);
    } else {
      try {
        final snap = await client.from('profiles').select('id');
        targetUserIds = (snap as List).map((data) => data['id'].toString()).toList();
      } catch (e) {
        debugPrint("CampusKart: sendNotification user list error: $e");
      }
    }

    for (var userId in targetUserIds) {
      try {
        await client.from('notifications').insert({
          'user_id': userId,
          'title': title,
          'message': message,
          'is_read': false,
        });
      } catch (e) {
        debugPrint("CampusKart: sendNotification insert error for $userId: $e");
      }
    }
  }

  Stream<List<Map<String, dynamic>>> streamNotifications() {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((doc) => {
                  'id': doc['id'],
                  'userId': doc['user_id'],
                  'title': doc['title'],
                  'message': doc['message'],
                  'isRead': doc['is_read'],
                  'createdAt': doc['created_at'],
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> streamNotificationsForUser(String uid) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .map((list) {
          final mapped = list.map((doc) => {
                'id': doc['id'],
                'userId': doc['user_id'],
                'title': doc['title'],
                'message': doc['message'],
                'isRead': doc['is_read'],
                'createdAt': doc['created_at'],
              }).toList();
          mapped.sort((a, b) => DateTime.parse(b['createdAt'].toString()).compareTo(DateTime.parse(a['createdAt'].toString())));
          return mapped;
        });
  }

  Future<void> sendTimerNotification({
    required String notificationId,
    required String title,
    required String message,
    required String type,
    String? imageUrl,
    String? productId,
    String? productType,
  }) async {
    await sendNotification(title: title, message: message);
  }

  // ==========================================
  // --- FAST FOOD TIMER SETTINGS ---
  // ==========================================

  Stream<Map<String, dynamic>> streamFastFoodSettings() {
    return client
        .from('settings')
        .stream(primaryKey: ['id'])
        .eq('id', 'global')
        .map((list) {
          if (list.isEmpty) return {};
          final data = list.first;
          return {
            'fastFoodEnabled': data['fast_food_enabled'] ?? false,
            'timerDuration': data['timer_duration'] ?? 0,
            'timerStartedAt': data['timer_started_at'],
            'timerEndsAt': data['timer_ends_at'],
            'enableHalfTimeReminder': data['enable_half_time_reminder'] ?? true,
            'enableTenMinReminder': data['enable_ten_min_reminder'] ?? true,
            'enableClosingNotification': data['enable_closing_notification'] ?? true,
            'halfTimeReminderSent': data['half_time_reminder_sent'] ?? false,
            'tenMinReminderSent': data['ten_min_reminder_sent'] ?? false,
            'closingNotificationSent': data['closing_notification_sent'] ?? false,
          };
        });
  }

  Future<void> updateFastFoodSettings(Map<String, dynamic> settings) async {
    final Map<String, dynamic> dbSettings = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (settings.containsKey('fastFoodEnabled')) dbSettings['fast_food_enabled'] = settings['fastFoodEnabled'];
    if (settings.containsKey('timerDuration')) dbSettings['timer_duration'] = settings['timerDuration'];
    if (settings.containsKey('timerStartedAt')) dbSettings['timer_started_at'] = settings['timerStartedAt'];
    if (settings.containsKey('timerEndsAt')) dbSettings['timer_ends_at'] = settings['timerEndsAt'];
    if (settings.containsKey('enableHalfTimeReminder')) dbSettings['enable_half_time_reminder'] = settings['enableHalfTimeReminder'];
    if (settings.containsKey('enableTenMinReminder')) dbSettings['enable_ten_min_reminder'] = settings['enableTenMinReminder'];
    if (settings.containsKey('enableClosingNotification')) dbSettings['enable_closing_notification'] = settings['enableClosingNotification'];
    if (settings.containsKey('halfTimeReminderSent')) dbSettings['half_time_reminder_sent'] = settings['halfTimeReminderSent'];
    if (settings.containsKey('tenMinReminderSent')) dbSettings['ten_min_reminder_sent'] = settings['tenMinReminderSent'];
    if (settings.containsKey('closingNotificationSent')) dbSettings['closing_notification_sent'] = settings['closingNotificationSent'];

    await client
        .from('settings')
        .update(dbSettings)
        .eq('id', 'global');
  }

  Future<void> markNotificationRead(String firstArg, [String? secondArg]) async {
    final String targetNotifId = secondArg ?? firstArg;
    if (targetNotifId.isEmpty) return;
    try {
      await client.from('notifications').update({'is_read': true}).eq('id', targetNotifId);
    } catch (e) {
      debugPrint("CampusKart: markNotificationRead error: $e");
    }
  }

  // ==========================================
  // --- ADMIN CUSTOMERS QUERY ---
  // ==========================================

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snap = await client.from('profiles').select().order('created_at', ascending: false);
      return (snap as List).map((data) => UserModel.fromMap(data, data['id'] ?? '')).toList();
    } catch (e) {
      debugPrint("CampusKart: getAllUsers error: $e");
      return [];
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((data) => UserModel.fromMap(data, data['id'] ?? ''))
            .toList());
  }

  Future<void> updateUserFCMToken(String uid, String token) async {
    try {
      await client.from('profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);
    } catch (e) {
      debugPrint("CampusKart: updateUserFCMToken error: $e");
    }
  }

  Future<void> updateOneSignalId(String uid, String oneSignalId) async {
    try {
      await client.from('profiles').update({
        'onesignal_id': oneSignalId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);
    } catch (e) {
      debugPrint("CampusKart: updateOneSignalId error: $e");
    }
  }

  Future<void> registerPushSubscription({
    required String uid,
    required String subscriptionId,
    String provider = 'onesignal',
    String? deviceType,
  }) async {
    try {
      // 1. Update profiles table for backwards compatibility
      await updateOneSignalId(uid, subscriptionId);

      // 2. Upsert into user_push_subscriptions table for multi-device support
      await client.from('user_push_subscriptions').upsert({
        'user_id': uid,
        'subscription_id': subscriptionId,
        'provider': provider,
        'device_type': deviceType,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,subscription_id');
    } catch (e) {
      debugPrint("CampusKart: registerPushSubscription error: $e");
    }
  }
}
