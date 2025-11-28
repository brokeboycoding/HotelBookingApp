import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> generateSampleHotelData() async {
  final firestore = FirebaseFirestore.instance;

  // ROOM TYPES
  final roomTypes = [
    {
      "id": "standard",
      "name": "Standard",
      "basePrice": 350000,
      "description": "Phòng tiêu chuẩn, đầy đủ tiện nghi."
    },
    {
      "id": "deluxe",
      "name": "Deluxe",
      "basePrice": 550000,
      "description": "Phòng rộng rãi, view đẹp, nội thất cao cấp."
    },
    {
      "id": "vip",
      "name": "VIP",
      "basePrice": 850000,
      "description": "Phòng VIP sang trọng, có bồn tắm, view biển."
    }
  ];

  for (var type in roomTypes) {
    await firestore
        .collection("room_types")
        .doc(type["id"]?.toString())
        .set(type);
  }


  // ROOMS
  final rooms = [
    {
      "roomNumber": "301",
      "typeId": "standard",
      "price": 350000,
      "status": "available",
      "imageUrl":
      "https://cf.bstatic.com/xdata/images/hotel/max1024x768/272232841.jpg?k=1f"
    },
    {
      "roomNumber": "302",
      "typeId": "standard",
      "price": 360000,
      "status": "occupied",
      "imageUrl":
      "https://cf.bstatic.com/xdata/images/hotel/max1024x768/244045232.jpg?k=2f"
    },
    {
      "roomNumber": "501",
      "typeId": "deluxe",
      "price": 550000,
      "status": "available",
      "imageUrl":
      "https://cf.bstatic.com/xdata/images/hotel/max1024x768/297119822.jpg?k=3f"
    },
    {
      "roomNumber": "502",
      "typeId": "deluxe",
      "price": 570000,
      "status": "maintenance",
      "imageUrl":
      "https://cf.bstatic.com/xdata/images/hotel/max1024x768/237554211.jpg?k=4f"
    },
    {
      "roomNumber": "701",
      "typeId": "vip",
      "price": 850000,
      "status": "available",
      "imageUrl":
      "https://cf.bstatic.com/xdata/images/hotel/max1024x768/236451992.jpg?k=5f"
    },
  ];

  for (var room in rooms) {
    await firestore.collection("rooms").add({
      ...room,
      "description": "Phòng đẹp, rộng rãi, đầy đủ tiện nghi.",
      "created_at": Timestamp.now(),
    });
  }
}
