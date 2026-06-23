import 'package:maplibre/maplibre.dart';
import '../models/notam.dart';

abstract class NotamRepository {
  Future<List<Notam>> fetchNotamsByFirs(List<String> firs);
  Future<List<Notam>> fetchNotamsAroundPoint(Geographic point, int radiusMeters);
}
