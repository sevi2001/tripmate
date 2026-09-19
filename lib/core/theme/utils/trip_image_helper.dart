class TripImageHelper {
  static String getImage(String destination) {
    final name = destination.trim().toLowerCase();

    if (name.contains('dubai')) {
      return 'assets/destinations/dubai.jpg';
    }

    if (name.contains('kyoto')) {
      return 'assets/destinations/kyoto.jpg';
    }

    if (name.contains('tokyo')) {
      return 'assets/destinations/tokyo.jpg';
    }

    return 'assets/destinations/default.jpg';
  }
}