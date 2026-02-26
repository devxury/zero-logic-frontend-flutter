import 'package:objectbox/objectbox.dart';

@Entity()
class DeepDocument {
  @Id()
  int id = 0; 

  @Unique()
  @Index()
  String globalKey; 

  @Index()
  String collection; 

  String payload; 

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  DeepDocument({
    this.id = 0,
    required this.globalKey,
    required this.collection,
    required this.payload,
    required this.updatedAt,
  });
}