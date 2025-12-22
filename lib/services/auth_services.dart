import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_services.dart';

class AuthService {
  final FirebaseService _firebaseService = FirebaseService();

  // Đăng ký tài khoản mới
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    try {
      // Tạo tài khoản Firebase Auth
      UserCredential userCredential = await _firebaseService.auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Tạo document trong Firestore
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firebaseService.usersCollection
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  // Đăng nhập
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseService.auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Kiểm tra tài khoản có bị vô hiệu hóa không
      DocumentSnapshot userDoc = await _firebaseService.usersCollection
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        UserModel user = UserModel.fromFirestore(userDoc);
        if (!user.isActive) {
          await _firebaseService.auth.signOut();
          throw 'Tài khoản đã bị vô hiệu hóa';
        }
        return user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _firebaseService.auth.signOut();
    } catch (e) {
      throw 'Không thể đăng xuất: $e';
    }
  }

  // Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUserData() async {
    try {
      String? uid = _firebaseService.currentUserId;
      if (uid == null) return null;

      DocumentSnapshot doc = await _firebaseService.usersCollection
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Không thể lấy thông tin người dùng: $e';
    }
  }

  // Stream user data
  Stream<UserModel?> streamCurrentUserData() {
    String? uid = _firebaseService.currentUserId;
    if (uid == null) return Stream.value(null);

    return _firebaseService.usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Không thể gửi email đặt lại mật khẩu: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _firebaseService.usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      throw 'Không thể cập nhật thông tin: $e';
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _firebaseService.currentUser;
      if (user == null) throw 'Người dùng chưa đăng nhập';

      // Xác thực lại người dùng
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Không thể đổi mật khẩu: $e';
    }
  }

  // Xử lý exception
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      default:
        return 'Lỗi xác thực: [${e.code}] ${e.message}';
    }
  }
}
