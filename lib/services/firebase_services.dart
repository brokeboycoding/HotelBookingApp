import 'package:booking_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Collection references tra ve collection trong firestore
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get hotelsCollection => _firestore.collection('hotels');
  CollectionReference get roomsCollection => _firestore.collection('rooms');
  CollectionReference get bookingsCollection =>
      _firestore.collection('bookings');
  CollectionReference get reviewsCollection => _firestore.collection('reviews');
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get reportsCollection => _firestore.collection('reports');

  // Khoi tao Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  String? get currentUserId => _auth.currentUser?.uid;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
