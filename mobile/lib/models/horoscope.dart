class Horoscope {
  final String sign;
  final String title;
  final String text;

  Horoscope({required this.sign, required this.title, required this.text});

  factory Horoscope.fromJson(Map<String, dynamic> json) {
    return Horoscope(
      sign: json['sign'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}
