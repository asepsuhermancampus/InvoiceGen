import 'dart:convert';

class TemplateElement {
  String id;
  String type; // 'text', 'image', 'rectangle', 'line'
  double x;
  double y;
  double width;
  double height;
  String content; // Text or path
  double fontSize;
  String colorHex;
  bool isBold;
  bool isItalic;
  String alignment; // 'left', 'center', 'right'

  TemplateElement({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 50,
    this.content = '',
    this.fontSize = 12,
    this.colorHex = '#000000',
    this.isBold = false,
    this.isItalic = false,
    this.alignment = 'left',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'content': content,
    'fontSize': fontSize,
    'colorHex': colorHex,
    'isBold': isBold,
    'isItalic': isItalic,
    'alignment': alignment,
  };

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    return TemplateElement(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 100).toDouble(),
      height: (json['height'] ?? 50).toDouble(),
      content: json['content'] ?? '',
      fontSize: (json['fontSize'] ?? 12).toDouble(),
      colorHex: json['colorHex'] ?? '#000000',
      isBold: json['isBold'] ?? false,
      isItalic: json['isItalic'] ?? false,
      alignment: json['alignment'] ?? 'left',
    );
  }
}

class TemplateSection {
  String id;
  String type; // 'header', 'table', 'footer', 'custom'
  double height;
  List<TemplateElement> elements;

  TemplateSection({
    required this.id,
    required this.type,
    this.height = 100,
    this.elements = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'height': height,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      id: json['id'] ?? '',
      type: json['type'] ?? 'custom',
      height: (json['height'] ?? 100).toDouble(),
      elements: (json['elements'] as List?)?.map((e) => TemplateElement.fromJson(e)).toList() ?? [],
    );
  }
}

class TemplateLayout {
  double pageWidth;
  double pageHeight;
  List<TemplateSection> sections;

  TemplateLayout({
    this.pageWidth = 595, // A4 Width
    this.pageHeight = 842, // A4 Height
    this.sections = const [],
  });

  Map<String, dynamic> toJson() => {
    'pageWidth': pageWidth,
    'pageHeight': pageHeight,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  factory TemplateLayout.fromJson(Map<String, dynamic> json) {
    return TemplateLayout(
      pageWidth: (json['pageWidth'] ?? 595).toDouble(),
      pageHeight: (json['pageHeight'] ?? 842).toDouble(),
      sections: (json['sections'] as List?)?.map((s) => TemplateSection.fromJson(s)).toList() ?? [],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static TemplateLayout fromJsonString(String jsonStr) => TemplateLayout.fromJson(jsonDecode(jsonStr));
}
