import '../models/design.dart';

class DesignRepository {
  static final List<Design> _designs = [];

  static void addDesign(Design design) {
    _designs.add(design);
  }

  static List<Design> get designs => List.unmodifiable(_designs);
}
