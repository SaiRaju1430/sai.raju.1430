import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/personal_request_model.dart';
import '../../models/fast_food_item_model.dart';
import '../../models/fast_food_order_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseInitialized = false;
  
  // Mock In-Memory Database for Offline Mode Fallback
  final List<UserModel> _mockUsers = [];
  final List<ProductModel> _mockProducts = [];
  final List<OrderModel> _mockOrders = [];
  final List<PersonalRequestModel> _mockPersonalRequests = [];
  final List<FastFoodItemModel> _mockFastFoodItems = [];
  final List<FastFoodOrderModel> _mockFastFoodOrders = [];
  final List<Map<String, dynamic>> _mockBroadcasts = [];
  final List<Map<String, dynamic>> _mockNotifications = [];
  bool _mockShopAvailable = true;
  bool _mockSendNotificationOnNewItem = true;
  final Map<String, dynamic> _mockFastFoodSettings = {
    'fastFoodEnabled': false,
    'timerDuration': 0,
    'timerStartedAt': null,
    'timerEndsAt': null,
    'enableHalfTimeReminder': true,
    'enableTenMinReminder': true,
    'enableClosingNotification': true,
    'halfTimeReminderSent': false,
    'tenMinReminderSent': false,
    'closingNotificationSent': false,
  };

  UserModel? _currentMockUser;

  // Stream Controllers for Mock Realtime Sync
  final StreamController<List<ProductModel>> _productsController = StreamController<List<ProductModel>>.broadcast();
  final StreamController<List<OrderModel>> _ordersController = StreamController<List<OrderModel>>.broadcast();
  final StreamController<List<PersonalRequestModel>> _requestsController = StreamController<List<PersonalRequestModel>>.broadcast();
  final StreamController<List<FastFoodItemModel>> _fastFoodItemsController = StreamController<List<FastFoodItemModel>>.broadcast();
  final StreamController<List<FastFoodOrderModel>> _fastFoodOrdersController = StreamController<List<FastFoodOrderModel>>.broadcast();
  final StreamController<bool> _availabilityController = StreamController<bool>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _broadcastsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _notificationsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _fastFoodSettingsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _sendNotificationOnNewItemController = StreamController<bool>.broadcast();

  bool get isOfflineMode => !_isFirebaseInitialized;

  File get _sessionFile => File('${Directory.systemTemp.path}/campuskart_session.json');

  Future<void> _saveMockSession(UserModel user) async {
    try {
      await _sessionFile.writeAsString(jsonEncode(user.toMap()));
    } catch (e) {
      print("CampusKart: Failed to save mock session: $e");
    }
  }

  Future<void> _clearMockSession() async {
    try {
      if (await _sessionFile.exists()) {
        await _sessionFile.delete();
      }
    } catch (e) {
      print("CampusKart: Failed to clear mock session: $e");
    }
  }

  Future<UserModel?> _loadMockSession() async {
    try {
      if (await _sessionFile.exists()) {
        String content = await _sessionFile.readAsString();
        Map<String, dynamic> data = jsonDecode(content);
        return UserModel.fromMap(data, data['uid'] ?? '');
      }
    } catch (e) {
      print("CampusKart: Failed to load mock session: $e");
    }
    return null;
  }

  /// Initialize Firebase or fallback to Mock Mode
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
      } else {
        // We catch failure if google-services.json is absent or environment lacks config
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isFirebaseInitialized = true;
      }
      print("CampusKart: Firebase initialized successfully.");
    } catch (e) {
      _isFirebaseInitialized = false;
      print("CampusKart: Firebase initialization failed. Falling back to offline Mock Database.");
      _setupInitialMockData();
    }

    if (!_isFirebaseInitialized) {
      _currentMockUser = await _loadMockSession();
    }
  }

  void _setupInitialMockData() {
    // Add default admin & customer
    _mockUsers.add(UserModel(uid: 'admin123', name: 'Campus Owner', mobile: '9999999999', role: 'admin'));
    _mockUsers.add(UserModel(uid: 'admin456', name: 'Campus Owner', mobile: '9515639193', role: 'admin'));
    _mockUsers.add(UserModel(uid: 'cust123', name: 'John Doe', mobile: '8888888888', role: 'customer'));
    
    // Add default products
    _mockProducts.addAll([
      ProductModel(
        id: 'p1',
        name: 'Fresh Tomatoes',
        category: 'Vegetables',
        price: 40.0,
        quantity: 20,
        imageUrl: 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=400',
        description: 'Fresh, organic, and juicy red tomatoes sourced directly from local farms. Perfect for salads, curries, and daily cooking.',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p2',
        name: 'Apples (Red)',
        category: 'Fruits',
        price: 180.0,
        quantity: 15,
        imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
        description: 'Sweet, crisp, and high-quality premium red apples from Kashmiri orchards. Packed with nutrients and delicious flavor.',
        unit: 'kg',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p3',
        name: 'Basmati Rice 1kg',
        category: 'Groceries',
        price: 120.0,
        quantity: 30,
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
        description: 'Premium aged long grain Basmati rice. Offers an exquisite aroma and perfect non-sticky texture after cooking.',
        unit: 'packet',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p4',
        name: 'Mango Pickles',
        category: 'Groceries',
        price: 90.0,
        quantity: 10,
        imageUrl: 'https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?w=400',
        description: 'Traditional tangy and spicy home-style mango pickle made with premium quality mangoes and authentic spices.',
        unit: 'packet',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p5',
        name: 'Potato Chips',
        category: 'Snacks',
        price: 30.0,
        quantity: 50,
        imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400',
        description: 'Crispy, light, and perfectly salted classic potato chips. An excellent snack choice for any time of the day.',
        unit: 'packet',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p6',
        name: 'Spiral Notebook',
        category: 'Stationery',
        price: 60.0,
        quantity: 25,
        imageUrl: 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400',
        description: 'High-quality A4 spiral notebook. Features standard single-ruled pages with smooth paper suitable for regular writing.',
        unit: 'piece',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p7',
        name: 'Amul Butter 100g',
        category: 'Dairy',
        price: 55.0,
        quantity: 40,
        imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400',
        description: 'Rich, creamy, and classic pasteurized salted butter. A delicious spread for bread, toast, and ideal for home baking.',
        unit: 'packet',
        available: true,
        createdDate: DateTime.now(),
      ),
      ProductModel(
        id: 'p8',
        name: 'Nivea Face Wash',
        category: 'Snacks', // Keeping consistent category or snacks/personal care
        price: 150.0,
        quantity: 8,
        imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400',
        description: 'Gentle purifying face wash formulated to deeply cleanse your skin, leaving it feeling completely fresh and hydrated.',
        unit: 'piece',
        available: true,
        createdDate: DateTime.now(),
      ),
    ]);

    _productsController.add(List.from(_mockProducts));
    _ordersController.add(List.from(_mockOrders));
    _requestsController.add(List.from(_mockPersonalRequests));
    _availabilityController.add(_mockShopAvailable);

    // Add default fast food items
    _mockFastFoodItems.addAll([
      FastFoodItemModel(
        id: 'ff1',
        name: 'Paneer Burger',
        description: 'Juicy paneer patty with crispy veggies and cheese sauce.',
        category: 'Burgers',
        price: 90.0,
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        available: true,
        createdAt: DateTime.now(),
      ),
      FastFoodItemModel(
        id: 'ff2',
        name: 'Cheese Pizza',
        description: 'Classic fresh dough pizza topped with lots of mozzarella cheese.',
        category: 'Pizzas',
        price: 140.0,
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        available: true,
        createdAt: DateTime.now(),
      ),
      FastFoodItemModel(
        id: 'ff3',
        name: 'Crispy French Fries',
        description: 'Golden salted crispy potato fries served with dip.',
        category: 'Sides',
        price: 60.0,
        imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=400',
        available: false, // Out of stock
        createdAt: DateTime.now(),
      ),
    ]);
    _fastFoodItemsController.add(List.from(_mockFastFoodItems));
    _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
  }

  // --- AUTHENTICATION METHODS ---

  Future<UserModel> register(String name, String mobile, String password, String role) async {
    if (_isFirebaseInitialized) {
      try {
        final String email = '$mobile@campuskart.com';
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 4));
        
        await cred.user!.updateDisplayName(name).timeout(const Duration(seconds: 2)).catchError((_) {});
        
        UserModel user = UserModel(uid: cred.user!.uid, name: name, mobile: mobile, role: role);
        try {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(user.toMap()).timeout(const Duration(seconds: 4));
        } catch (e) {
          print("CampusKart: Firestore profile write failed or timed out: $e");
        }
        return user;
      } catch (e) {
        print("CampusKart: Firebase registration failed: $e");
        rethrow;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      UserModel user = _registerMock(name, mobile, password, role);
      await _saveMockSession(user);
      return user;
    }
  }

  UserModel _registerMock(String name, String mobile, String password, String role) {
    if (_mockUsers.any((u) => u.mobile == mobile)) {
      throw Exception('User with this mobile number already exists.');
    }
    String uid = 'uid_${DateTime.now().millisecondsSinceEpoch}';
    UserModel newUser = UserModel(uid: uid, name: name, mobile: mobile, role: role);
    _mockUsers.add(newUser);
    _currentMockUser = newUser;
    return newUser;
  }

  Future<UserModel> _getOrCreateFirestoreUser(User fbUser, String mobile, String defaultRole) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get().timeout(const Duration(seconds: 4));
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("CampusKart: Firestore error getting user: $e");
    }
    
    UserModel user = UserModel(
      uid: fbUser.uid,
      name: fbUser.displayName ?? (defaultRole == 'admin' ? 'Campus Owner' : 'Student'),
      mobile: mobile,
      role: defaultRole,
    );
    try {
      await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set(user.toMap()).timeout(const Duration(seconds: 4));
    } catch (e) {
      print("CampusKart: Firestore error setting user: $e");
    }
    return user;
  }

  Future<UserModel> login(String mobile, String password) async {
    if (_isFirebaseInitialized) {
      try {
        final String email = '$mobile@campuskart.com';
        
        // Auto-register/login admin if predefined credentials match
        if ((mobile == '9999999999' || mobile == '9515639193') && password == '123456') {
          try {
            UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            ).timeout(const Duration(seconds: 4));
            
            return await _getOrCreateFirestoreUser(cred.user!, mobile, 'admin');
          } catch (signInError) {
            try {
              UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: password,
              ).timeout(const Duration(seconds: 4));
              
              await cred.user!.updateDisplayName('Campus Owner').timeout(const Duration(seconds: 2)).catchError((_) {});
              
              return await _getOrCreateFirestoreUser(cred.user!, mobile, 'admin');
            } catch (registerError) {
              print("CampusKart: Auto admin registration failed: $registerError");
            }
          }
        }
        
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 4));
        
        return await _getOrCreateFirestoreUser(cred.user!, mobile, (mobile == '9999999999' || mobile == '9515639193') ? 'admin' : 'customer');
      } catch (e) {
        print("CampusKart: Firebase login failed: $e");
        rethrow;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      UserModel user = _loginMock(mobile, password);
      await _saveMockSession(user);
      return user;
    }
  }

  UserModel _loginMock(String mobile, String password) {
    try {
      UserModel user = _mockUsers.firstWhere((u) => u.mobile == mobile);
      _currentMockUser = user;
      return user;
    } catch (e) {
      throw Exception('User not found. Please register.');
    }
  }

  Future<void> logout() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
    } else {
      _currentMockUser = null;
      await _clearMockSession();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_isFirebaseInitialized) {
      try {
        User? fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser == null) return null;
        try {
          DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get().timeout(const Duration(seconds: 4));
          if (doc.exists) {
            return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
        } catch (e) {
          print("CampusKart: Firestore profile fetch failed, using fallback from Auth credential: $e");
        }

        // Fallback to constructing user model from Auth credential if firestore is offline or fails
        final email = fbUser.email ?? '';
        final mobile = email.split('@').first;
        final role = (mobile == '9999999999' || mobile == '9515639193') ? 'admin' : 'customer';
        final name = fbUser.displayName ?? 'Student';
        return UserModel(
          uid: fbUser.uid,
          name: name,
          mobile: mobile,
          role: role,
        );
      } catch (e) {
        print("CampusKart: Firebase getCurrentUser failed: $e");
        return null;
      }
    } else {
      if (_currentMockUser == null) {
        _currentMockUser = await _loadMockSession();
      }
      return _currentMockUser;
    }
  }

  // --- PRODUCT MANAGEMENT (CRUD) ---

  Stream<List<ProductModel>> streamProducts() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      yield List.from(_mockProducts);
      yield* _productsController.stream;
    }
  }

  Future<String> addProduct(String name, String category, double price, int quantity, String imageUrl, String description, String unit) async {
    if (_isFirebaseInitialized) {
      final ref = await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'category': category,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'description': description,
        'unit': unit,
        'available': quantity > 0,
        'createdDate': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      String id = 'prod_${DateTime.now().millisecondsSinceEpoch}';
      ProductModel newProd = ProductModel(
        id: id,
        name: name,
        category: category,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl.isEmpty ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400' : imageUrl,
        description: description,
        unit: unit,
        available: quantity > 0,
        createdDate: DateTime.now(),
      );
      _mockProducts.insert(0, newProd);
      _productsController.add(List.from(_mockProducts));
      return id;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('products').doc(product.id).update(product.toMap());
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _mockProducts[index] = product.copyWith(available: product.quantity > 0);
        _productsController.add(List.from(_mockProducts));
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockProducts.removeWhere((p) => p.id == id);
      _productsController.add(List.from(_mockProducts));
    }
  }

  // --- ORDER MANAGEMENT ---

  Stream<List<OrderModel>> streamCustomerOrders(String customerId) async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            List<OrderModel> orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();
            // Sort by date in memory since Firestore indexing might take time
            orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
            return orders;
          });
    } else {
      yield _mockOrders.where((order) => order.customerId == customerId).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      yield* _ordersController.stream.map((list) =>
          list.where((order) => order.customerId == customerId).toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate)));
    }
  }

  Stream<List<OrderModel>> streamAllOrders() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            List<OrderModel> orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();
            return orders;
          });
    } else {
      yield List.from(_mockOrders)..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      yield* _ordersController.stream.map((list) => List.from(list)
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate)));
    }
  }

  Future<String> placeOrder(OrderModel order) async {
    if (_isFirebaseInitialized) {
      try {
        // Create document in Firestore
        DocumentReference ref = await FirebaseFirestore.instance.collection('orders').add(order.toMap());
        
        // Deduct inventory quantities for general items
        for (var item in order.items) {
          DocumentReference prodRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentSnapshot snap = await transaction.get(prodRef);
            if (snap.exists) {
              int currentQty = snap['quantity'] ?? 0;
              int newQty = currentQty - item.quantity;
              if (newQty < 0) newQty = 0;
              transaction.update(prodRef, {
                'quantity': newQty,
                'available': newQty > 0,
              });
            }
          });
        }
        
        print("Order successfully created in Firestore with ID: ${ref.id}");
        return ref.id;
      } catch (e) {
        print("CampusKart: Firebase order failed: $e");
        rethrow; // Do not fallback to mock database, let it fail as requested
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      final orderId = _placeMockOrder(order);
      print("Order successfully created in Mock DB with ID: $orderId");
      return orderId;
    }
  }

  String _placeMockOrder(OrderModel order) {
    String orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    
    // Update local product inventory quantities
    for (var item in order.items) {
      int pIndex = _mockProducts.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        int newQty = _mockProducts[pIndex].quantity - item.quantity;
        if (newQty < 0) newQty = 0;
        _mockProducts[pIndex] = _mockProducts[pIndex].copyWith(
          quantity: newQty,
          available: newQty > 0,
        );
      }
    }
    _productsController.add(List.from(_mockProducts));

    OrderModel newOrder = OrderModel(
      id: orderId,
      customerId: order.customerId,
      customerName: order.customerName,
      customerMobile: order.customerMobile,
      blockName: order.blockName,
      roomNumber: order.roomNumber,
      items: order.items,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      paymentId: order.paymentId,
      paymentAccountName: order.paymentAccountName,
      paymentMobileNumber: order.paymentMobileNumber,
      verificationCode: order.verificationCode,
      status: 'Pending',
      orderDate: DateTime.now(),
    );

    _mockOrders.add(newOrder);
    _ordersController.add(List.from(_mockOrders));
    return orderId;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': status,
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _mockOrders[index] = OrderModel(
          id: _mockOrders[index].id,
          customerId: _mockOrders[index].customerId,
          customerName: _mockOrders[index].customerName,
          customerMobile: _mockOrders[index].customerMobile,
          blockName: _mockOrders[index].blockName,
          roomNumber: _mockOrders[index].roomNumber,
          items: _mockOrders[index].items,
          subtotal: _mockOrders[index].subtotal,
          deliveryFee: _mockOrders[index].deliveryFee,
          total: _mockOrders[index].total,
          paymentId: _mockOrders[index].paymentId,
          paymentAccountName: _mockOrders[index].paymentAccountName,
          paymentMobileNumber: _mockOrders[index].paymentMobileNumber,
          verificationCode: _mockOrders[index].verificationCode,
          status: status,
          orderDate: _mockOrders[index].orderDate,
        );
        _ordersController.add(List.from(_mockOrders));
      }
    }
  }

  // --- PERSONAL REQUESTS ---

  Stream<List<PersonalRequestModel>> streamCustomerRequests(String customerId) async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('personal_requests')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            List<PersonalRequestModel> requests = snapshot.docs
                .map((doc) => PersonalRequestModel.fromMap(doc.data(), doc.id))
                .toList();
            requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
            return requests;
          });
    } else {
      yield _mockPersonalRequests.where((req) => req.customerId == customerId).toList()
        ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
      yield* _requestsController.stream.map((list) =>
          list.where((req) => req.customerId == customerId).toList()
            ..sort((a, b) => b.requestDate.compareTo(a.requestDate)));
    }
  }

  Stream<List<PersonalRequestModel>> streamAllRequests() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('personal_requests')
          .snapshots()
          .map((snapshot) {
            List<PersonalRequestModel> requests = snapshot.docs
                .map((doc) => PersonalRequestModel.fromMap(doc.data(), doc.id))
                .toList();
            requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
            return requests;
          });
    } else {
      yield List.from(_mockPersonalRequests)..sort((a, b) => b.requestDate.compareTo(a.requestDate));
      yield* _requestsController.stream.map((list) => List.from(list)
        ..sort((a, b) => b.requestDate.compareTo(a.requestDate)));
    }
  }

  Future<void> submitPersonalRequest(PersonalRequestModel request) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('personal_requests').add(request.toMap()).timeout(const Duration(seconds: 4));
      } catch (e) {
        print("CampusKart: Firebase custom request failed or timed out. Falling back to offline database.");
        _submitMockPersonalRequest(request);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _submitMockPersonalRequest(request);
    }
  }

  void _submitMockPersonalRequest(PersonalRequestModel request) {
    String reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    PersonalRequestModel newReq = request.copyWith(
      id: reqId,
      imageUrl: request.imageUrl.isEmpty 
          ? 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400' 
          : request.imageUrl,
      status: 'Pending Review',
      requestDate: DateTime.now(),
    );
    _mockPersonalRequests.add(newReq);
    _requestsController.add(List.from(_mockPersonalRequests));
  }

  Future<void> updatePersonalRequest(PersonalRequestModel request) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('personal_requests')
          .doc(request.id)
          .update(request.toMap());
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockPersonalRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _mockPersonalRequests[index] = request;
        _requestsController.add(List.from(_mockPersonalRequests));
      }
    }
  }

  /// Marks a personal request as Delivered with deliveryVerified=true and deliveredAt timestamp.
  Future<void> deliverPersonalRequest(String requestId) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('personal_requests')
          .doc(requestId)
          .update({
        'status': 'Delivered',
        'deliveryVerified': true,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockPersonalRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _mockPersonalRequests[index] = _mockPersonalRequests[index].copyWith(
          status: 'Delivered',
        );
        _requestsController.add(List.from(_mockPersonalRequests));
      }
    }
  }


  Future<void> updatePersonalRequestStatus(String requestId, String status) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('personal_requests').doc(requestId).update({
        'status': status,
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockPersonalRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _mockPersonalRequests[index] = _mockPersonalRequests[index].copyWith(
          status: status,
        );
        _requestsController.add(List.from(_mockPersonalRequests));
      }
    }
  }

  // --- SHOP AVAILABILITY ---

  Stream<bool> streamShopAvailability() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('settings')
          .doc('ownerAvailable')
          .snapshots()
          .map((snapshot) => snapshot.data()?['ownerAvailable'] ?? true);
    } else {
      yield _mockShopAvailable;
      yield* _availabilityController.stream;
    }
  }

  Future<void> toggleShopAvailability(bool available) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('ownerAvailable')
          .set({'ownerAvailable': available}, SetOptions(merge: true));
    } else {
      _mockShopAvailable = available;
      _availabilityController.add(available);
    }
  }

  // --- FAST FOOD MANAGEMENT ---

  Stream<List<FastFoodItemModel>> streamFastFoodItems() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('fast_food_items')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FastFoodItemModel.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      yield List.from(_mockFastFoodItems);
      yield* _fastFoodItemsController.stream;
    }
  }

  Future<String> addFastFoodItem(String name, String description, String category, double price, String imageUrl, bool available) async {
    if (_isFirebaseInitialized) {
      final ref = await FirebaseFirestore.instance.collection('fast_food_items').add({
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'imageUrl': imageUrl,
        'available': available,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      String id = 'ff_${DateTime.now().millisecondsSinceEpoch}';
      FastFoodItemModel newItem = FastFoodItemModel(
        id: id,
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrl: imageUrl.isEmpty ? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400' : imageUrl,
        available: available,
        createdAt: DateTime.now(),
      );
      _mockFastFoodItems.insert(0, newItem);
      _fastFoodItemsController.add(List.from(_mockFastFoodItems));
      return id;
    }
  }

  Future<void> updateFastFoodItem(FastFoodItemModel item) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('fast_food_items')
          .doc(item.id)
          .update(item.toMap());
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockFastFoodItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _mockFastFoodItems[index] = item;
        _fastFoodItemsController.add(List.from(_mockFastFoodItems));
      }
    }
  }

  Future<void> deleteFastFoodItem(String id) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('fast_food_items').doc(id).delete();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockFastFoodItems.removeWhere((i) => i.id == id);
      _fastFoodItemsController.add(List.from(_mockFastFoodItems));
    }
  }

  // --- FAST FOOD ORDERS ---

  Stream<List<FastFoodOrderModel>> streamCustomerFastFoodOrders(String customerId) async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('fast_food_orders')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            List<FastFoodOrderModel> orders = snapshot.docs
                .map((doc) => FastFoodOrderModel.fromMap(doc.data(), doc.id))
                .toList();
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          });
    } else {
      yield _mockFastFoodOrders.where((order) => order.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield* _fastFoodOrdersController.stream.map((list) =>
          list.where((order) => order.customerId == customerId).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
  }

  Stream<List<FastFoodOrderModel>> streamAllFastFoodOrders() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('fast_food_orders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FastFoodOrderModel.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      yield List.from(_mockFastFoodOrders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield* _fastFoodOrdersController.stream.map((list) => List.from(list)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
  }

  Future<String> placeFastFoodOrder(FastFoodOrderModel order) async {
    final code = order.deliveryCode.isNotEmpty ? order.deliveryCode : (Random().nextInt(9000) + 1000).toString();
    final status = 'Pending';

    final orderWithStatus = order.copyWith(
      deliveryCode: code,
      deliveryVerified: false,
      status: status,
    );

    if (_isFirebaseInitialized) {
      DocumentReference ref = await FirebaseFirestore.instance.collection('fast_food_orders').add(orderWithStatus.toMap());
      return ref.id;
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      String orderId = 'fford_${DateTime.now().millisecondsSinceEpoch}';
      FastFoodOrderModel newOrder = orderWithStatus.copyWith(
        orderId: orderId,
        createdAt: DateTime.now(),
      );
      _mockFastFoodOrders.add(newOrder);
      _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
      return orderId;
    }
  }

  /// Admin confirms online payment — retrieves the existing delivery code and sets status to Confirmed.
  Future<String> confirmFastFoodPayment(String orderId) async {
    String code = '';
    if (_isFirebaseInitialized) {
      final doc = await FirebaseFirestore.instance.collection('fast_food_orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        code = (data['deliveryOtp'] ?? data['deliveryCode'] ?? '').toString();
      }
      await FirebaseFirestore.instance.collection('fast_food_orders').doc(orderId).update({
        'status': 'Confirmed',
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockFastFoodOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        code = _mockFastFoodOrders[index].deliveryCode;
        _mockFastFoodOrders[index] = _mockFastFoodOrders[index].copyWith(
          status: 'Confirmed',
        );
        _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
      }
    }
    return code;
  }

  /// Admin rejects an online payment.
  Future<void> rejectFastFoodPayment(String orderId) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('fast_food_orders').doc(orderId).update({
        'status': 'Rejected',
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockFastFoodOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _mockFastFoodOrders[index] = _mockFastFoodOrders[index].copyWith(status: 'Rejected');
        _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
      }
    }
  }

  Future<void> updateFastFoodOrderStatus(String orderId, String status) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('fast_food_orders').doc(orderId).update({'status': status});
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockFastFoodOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _mockFastFoodOrders[index] = _mockFastFoodOrders[index].copyWith(status: status);
        _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
      }
    }
  }

  Future<void> verifyAndDeliverFastFoodOrder(String orderId) async {
    final now = DateTime.now();
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('fast_food_orders').doc(orderId).update({
        'status': 'Delivered',
        'deliveryVerified': true,
        'otpVerified': true,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      int index = _mockFastFoodOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _mockFastFoodOrders[index] = _mockFastFoodOrders[index].copyWith(
          status: 'Delivered',
          deliveryVerified: true,
          deliveredAt: now,
        );
        _fastFoodOrdersController.add(List.from(_mockFastFoodOrders));
      }
    }
  }

  // --- BROADCAST MESSAGES ---

  Stream<List<Map<String, dynamic>>> streamBroadcasts() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('admin_broadcasts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList());
    } else {
      yield List.from(_mockBroadcasts)..sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      yield* _broadcastsController.stream.map((list) => List.from(list)
        ..sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime)));
    }
  }

  Future<void> sendBroadcast({
    required String title,
    required String content,
    required String targetType,
    String? targetCustomerId,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'targetType': targetType,
      'targetCustomerId': targetCustomerId,
      'createdAt': _isFirebaseInitialized ? FieldValue.serverTimestamp() : DateTime.now(),
    };

    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance.collection('admin_broadcasts').add(data);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      final docId = 'bc_${DateTime.now().millisecondsSinceEpoch}';
      final mockData = {
        'id': docId,
        ...data,
        'createdAt': DateTime.now(),
      };
      _mockBroadcasts.insert(0, mockData);
      _broadcastsController.add(List.from(_mockBroadcasts));
    }
  }

  // --- USER NOTIFICATION SETTINGS ---

  Future<void> updateUserNotificationSettings(String uid, bool enabled) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'notificationsEnabled': enabled});
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      int idx = _mockUsers.indexWhere((u) => u.uid == uid);
      if (idx != -1) {
        _mockUsers[idx] = UserModel(
          uid: _mockUsers[idx].uid,
          name: _mockUsers[idx].name,
          mobile: _mockUsers[idx].mobile,
          role: _mockUsers[idx].role,
          notificationsEnabled: enabled,
        );
        if (_currentMockUser?.uid == uid) {
          _currentMockUser = _mockUsers[idx];
          await _saveMockSession(_currentMockUser!);
        }
      }
    }
  }

  // --- NEW ITEM NOTIFICATION SETTING ---

  Stream<bool> streamSendNotificationOnNewItem() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('settings')
          .doc('ownerAvailable')
          .snapshots()
          .map((snapshot) => snapshot.data()?['sendNotificationOnNewItem'] ?? true);
    } else {
      yield _mockSendNotificationOnNewItem;
      yield* _sendNotificationOnNewItemController.stream;
    }
  }

  Future<void> toggleSendNotificationOnNewItem(bool enabled) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('ownerAvailable')
          .set({'sendNotificationOnNewItem': enabled}, SetOptions(merge: true));
    } else {
      _mockSendNotificationOnNewItem = enabled;
      _sendNotificationOnNewItemController.add(enabled);
    }
  }

  // --- GLOBAL NOTIFICATIONS SYSTEM ---

  Future<void> _sendFCMThroughREST(String token, String title, String body) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final request = await client.postUrl(uri);
      
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      // Placeholder server key. The user can replace this with their actual Firebase Server Key.
      request.headers.set(HttpHeaders.authorizationHeader, 'key=YOUR_FCM_SERVER_KEY');
      
      final payload = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        }
      };
      
      request.write(jsonEncode(payload));
      final response = await request.close();
      print('CampusKart: FCM API response status: ${response.statusCode}');
    } catch (e) {
      print('CampusKart: FCM REST API error: $e');
    }
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    String? targetUserId,
  }) async {
    List<UserModel> targets = [];
    if (targetUserId != null) {
      if (_isFirebaseInitialized) {
        DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
        if (snap.exists) {
          targets.add(UserModel.fromMap(snap.data() as Map<String, dynamic>, snap.id));
        }
      } else {
        int idx = _mockUsers.indexWhere((u) => u.uid == targetUserId);
        if (idx != -1) {
          targets.add(_mockUsers[idx]);
        }
      }
    } else {
      if (_isFirebaseInitialized) {
        QuerySnapshot snap = await FirebaseFirestore.instance.collection('users').get();
        targets = snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } else {
        targets = List.from(_mockUsers);
      }
    }

    for (var user in targets) {
      final notifId = _isFirebaseInitialized 
          ? FirebaseFirestore.instance.collection('notifications').doc().id 
          : 'notif_${DateTime.now().millisecondsSinceEpoch}_${user.uid}_${(100 + (DateTime.now().microsecondsSinceEpoch % 900))}';
      
      final data = {
        'notificationId': notifId,
        'userId': user.uid,
        'title': title,
        'message': message,
        'createdAt': _isFirebaseInitialized ? FieldValue.serverTimestamp() : DateTime.now(),
        'isRead': false,
      };

      if (_isFirebaseInitialized) {
        await FirebaseFirestore.instance.collection('notifications').doc(notifId).set(data);
      } else {
        _mockNotifications.insert(0, {
          'id': notifId,
          ...data,
          'sentAt': DateTime.now(),
        });
      }

      if (user.notificationsEnabled && user.fcmToken != null && user.fcmToken!.isNotEmpty) {
        if (_isFirebaseInitialized) {
          await _sendFCMThroughREST(user.fcmToken!, title, message);
        } else {
          print('CampusKart: FCM Simulation to user: ${user.name} (${user.uid}) | token: ${user.fcmToken} | Title: $title | Msg: $message');
        }
      }
    }

    if (!_isFirebaseInitialized) {
      _notificationsController.add(List.from(_mockNotifications));
    }
  }

  Stream<List<Map<String, dynamic>>> streamNotifications() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList());
    } else {
      yield List.from(_mockNotifications)..sort((a, b) {
        final DateTime da = a['createdAt'] is DateTime ? a['createdAt'] : DateTime.parse(a['createdAt'].toString());
        final DateTime db = b['createdAt'] is DateTime ? b['createdAt'] : DateTime.parse(b['createdAt'].toString());
        return db.compareTo(da);
      });
      yield* _notificationsController.stream.map((list) => List.from(list)..sort((a, b) {
        final DateTime da = a['createdAt'] is DateTime ? a['createdAt'] : DateTime.parse(a['createdAt'].toString());
        final DateTime db = b['createdAt'] is DateTime ? b['createdAt'] : DateTime.parse(b['createdAt'].toString());
        return db.compareTo(da);
      }));
    }
  }

  Stream<List<Map<String, dynamic>>> streamNotificationsForUser(String uid) async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();
            list.sort((a, b) {
              final rawA = a['createdAt'];
              final rawB = b['createdAt'];
              final DateTime da = rawA is Timestamp ? rawA.toDate() : (rawA is DateTime ? rawA : (rawA is String ? DateTime.tryParse(rawA) ?? DateTime.now() : DateTime.now()));
              final DateTime db = rawB is Timestamp ? rawB.toDate() : (rawB is DateTime ? rawB : (rawB is String ? DateTime.tryParse(rawB) ?? DateTime.now() : DateTime.now()));
              return db.compareTo(da);
            });
            return list;
          });
    } else {
      yield _mockNotifications.where((n) => n['userId'] == uid).toList()
        ..sort((a, b) {
          final rawA = a['createdAt'];
          final rawB = b['createdAt'];
          final DateTime da = rawA is DateTime ? rawA : DateTime.parse(rawA.toString());
          final DateTime db = rawB is DateTime ? rawB : DateTime.parse(rawB.toString());
          return db.compareTo(da);
        });
      yield* _notificationsController.stream.map((list) =>
          list.where((n) => n['userId'] == uid).toList()
            ..sort((a, b) {
              final rawA = a['createdAt'];
              final rawB = b['createdAt'];
              final DateTime da = rawA is DateTime ? rawA : DateTime.parse(rawA.toString());
              final DateTime db = rawB is DateTime ? rawB : DateTime.parse(rawB.toString());
              return db.compareTo(da);
            }));
    }
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

  // --- FAST FOOD TIMER SETTINGS ---

  Stream<Map<String, dynamic>> streamFastFoodSettings() async* {
    if (_isFirebaseInitialized) {
      yield* FirebaseFirestore.instance
          .collection('settings')
          .doc('fastFoodSettings')
          .snapshots()
          .map((snapshot) => snapshot.data() ?? {});
    } else {
      yield _mockFastFoodSettings;
      yield* _fastFoodSettingsController.stream;
    }
  }

  Future<void> updateFastFoodSettings(Map<String, dynamic> settings) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('fastFoodSettings')
          .set(settings, SetOptions(merge: true));
    } else {
      _mockFastFoodSettings.addAll(settings);
      _fastFoodSettingsController.add(Map.from(_mockFastFoodSettings));
    }
  }

  // --- READ NOTIFICATION PERSISTENCE ---

  Stream<Set<String>> streamReadNotificationIds(String uid) async* {
    yield* streamNotificationsForUser(uid).map((list) {
      return list
          .where((n) => n['isRead'] == true)
          .map((n) => n['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  Future<void> markNotificationRead(String firstArg, [String? secondArg]) async {
    final String targetNotifId = secondArg ?? firstArg;
    
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(targetNotifId)
          .update({'isRead': true});
    } else {
      int idx = _mockNotifications.indexWhere((n) => n['notificationId'] == targetNotifId || n['id'] == targetNotifId);
      if (idx != -1) {
        final entry = Map<String, dynamic>.from(_mockNotifications[idx]);
        entry['isRead'] = true;
        _mockNotifications[idx] = entry;
        _notificationsController.add(List.from(_mockNotifications));
      }
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    if (_isFirebaseInitialized) {
      QuerySnapshot snap = await FirebaseFirestore.instance.collection('users').get();
      return snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } else {
      return List.from(_mockUsers);
    }
  }

  Future<void> updateUserFCMToken(String uid, String token) async {
    if (_isFirebaseInitialized) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    } else {
      int idx = _mockUsers.indexWhere((u) => u.uid == uid);
      if (idx != -1) {
        _mockUsers[idx] = _mockUsers[idx].copyWith(fcmToken: token);
        if (_currentMockUser?.uid == uid) {
          _currentMockUser = _mockUsers[idx];
          await _saveMockSession(_currentMockUser!);
        }
      }
    }
  }
}
