import 'template_models.dart';

class DefaultTemplates {
  static TemplateLayout get template1 {
    return TemplateLayout(
      pageWidth: 595,
      pageHeight: 842,
      sections: [
        TemplateSection(
          id: 'header',
          type: 'header',
          height: 150,
          elements: [
            TemplateElement(
              id: 'title',
              type: 'text',
              x: 400,
              y: 20,
              content: 'INVOICE',
              fontSize: 28,
              isBold: true,
              colorHex: '#333333',
            ),
            TemplateElement(
              id: 'company_name',
              type: 'text',
              x: 40,
              y: 40,
              content: '{{company_name}}',
              fontSize: 18,
              isBold: true,
            ),
            TemplateElement(
              id: 'company_address',
              type: 'text',
              x: 40,
              y: 60,
              content: '{{company_address}}\nTel: {{company_phone}}',
              fontSize: 10,
            ),
          ],
        ),
        TemplateSection(
          id: 'customer_info',
          type: 'custom',
          height: 100,
          elements: [
            TemplateElement(
              id: 'bill_to',
              type: 'text',
              x: 40,
              y: 120,
              content: 'Ditagihkan Kepada:\n{{customer_name}}\n{{customer_address}}',
              fontSize: 10,
            ),
            TemplateElement(
              id: 'inv_details',
              type: 'text',
              x: 400,
              y: 120,
              content: 'No Invoice: {{invoice_number}}\nTanggal: {{invoice_date}}',
              fontSize: 10,
            ),
          ]
        ),
        TemplateSection(
          id: 'table',
          type: 'table',
          height: 300,
          elements: [
            TemplateElement(
              id: 'table_el',
              type: 'table',
              x: 40,
              y: 200,
            )
          ]
        ),
        TemplateSection(
          id: 'summary',
          type: 'custom',
          height: 150,
          elements: [
            TemplateElement(
              id: 'subtotal',
              type: 'text',
              x: 350,
              y: 550,
              content: 'Subtotal: {{subtotal}}',
              fontSize: 10,
            ),
            TemplateElement(
              id: 'tax',
              type: 'text',
              x: 350,
              y: 570,
              content: 'PPN: {{tax}}',
              fontSize: 10,
            ),
            TemplateElement(
              id: 'grand_total',
              type: 'text',
              x: 350,
              y: 590,
              content: 'Total: {{grand_total}}',
              fontSize: 14,
              isBold: true,
            ),
            TemplateElement(
              id: 'terbilang',
              type: 'text',
              x: 40,
              y: 620,
              content: 'Terbilang:\n{{terbilang}}',
              fontSize: 10,
              isItalic: true,
            ),
          ]
        ),
      ],
    );
  }

  // Define 3 other templates...
  static TemplateLayout get template2 => template1; // Minimalis Modern (fallback for now)
  static TemplateLayout get template3 => template1; // Corporate (fallback)
  static TemplateLayout get template4 => template1; // Clean Elegant (fallback)
}
