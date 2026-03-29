import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_localizations.dart';

class StaticContentScreen extends ConsumerWidget {
  final String title;
  final String contentKey;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient.scale(0.1),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: _buildContent(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (contentKey == 'contact_us') {
      return SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.phone_rounded,
            title: l10n.tr('phone'),
            subtitle: '+966 50 000 0000',
            onTap: () => _launchUrl('tel:+966500000000'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.chat_bubble_rounded,
            title: 'WhatsApp',
            subtitle: '+966 50 000 0000',
            onTap: () => _launchUrl('https://wa.me/966500000000'),
          ),
          const SizedBox(height: 32),
        ]),
      );
    }

    // Privacy Policy & Terms of Service content
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    List<_Section> sections = [];

    if (contentKey == 'privacy_policy') {
      sections = isRtl
          ? [
              _Section('١. جمع البيانات',
                  'نقوم بجمع المعلومات الشخصية التي تقدمها عند إنشاء حسابك، مثل الاسم الكامل، البريد الإلكتروني، ورقم الهاتف. كما نجمع بيانات الاستخدام تلقائياً لتحسين تجربتك.'),
              _Section('٢. استخدام البيانات',
                  'نستخدم بياناتك لتقديم خدمات المنصة، معالجة الطلبات، التواصل معك بشأن حسابك، وتحسين خدماتنا. لن نستخدم بياناتك لأغراض تسويقية دون إذنك.'),
              _Section('٣. مشاركة البيانات',
                  'لا نبيع بياناتك الشخصية لأطراف ثالثة. قد نشارك معلومات محدودة مع مقدمي الخدمات الموثوقين لتسهيل عمليات الدفع والتوصيل فقط.'),
              _Section('٤. أمان البيانات',
                  'نطبق إجراءات أمنية متقدمة لحماية بياناتك من الوصول غير المصرح به، بما في ذلك التشفير والمراقبة المستمرة.'),
              _Section('٥. حقوق المستخدم',
                  'يحق لك طلب الاطلاع على بياناتك الشخصية، تعديلها، أو حذف حسابك في أي وقت من خلال إعدادات الملف الشخصي أو التواصل مع فريق الدعم.'),
              _Section('٦. خصوصية الأطفال',
                  'منصتنا غير موجهة للأشخاص دون سن ١٨ عاماً. لا نجمع بيانات الأطفال عن قصد.'),
              _Section('٧. تحديثات السياسة',
                  'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنبلغك بأي تغييرات جوهرية عبر التطبيق أو البريد الإلكتروني.'),
              _Section('٨. التواصل',
                  'لأي استفسارات حول خصوصيتك، يرجى التواصل معنا عبر صفحة "اتصل بنا" في التطبيق.'),
            ]
          : [
              _Section('1. Data Collection',
                  'We collect personal information you provide when creating your account, such as your full name, email address, and phone number. We also automatically collect usage data to improve your experience.'),
              _Section('2. Data Usage',
                  'We use your data to provide platform services, process orders, communicate with you about your account, and improve our services. We will not use your data for marketing purposes without your consent.'),
              _Section('3. Data Sharing',
                  'We do not sell your personal data to third parties. We may share limited information with trusted service providers solely to facilitate payment and delivery processes.'),
              _Section('4. Data Security',
                  'We implement advanced security measures to protect your data from unauthorized access, including encryption and continuous monitoring.'),
              _Section('5. User Rights',
                  'You have the right to access, modify, or delete your personal data at any time through your profile settings or by contacting our support team.'),
              _Section("6. Children's Privacy",
                  'Our platform is not intended for individuals under the age of 18. We do not knowingly collect data from children.'),
              _Section('7. Policy Updates',
                  'We may update this privacy policy from time to time. We will notify you of any material changes through the app or via email.'),
              _Section('8. Contact',
                  'For any privacy-related inquiries, please reach out to us through the "Contact Us" page in the app.'),
            ];
    } else if (contentKey == 'terms_of_service') {
      sections = isRtl
          ? [
              _Section('١. قبول الشروط',
                  'باستخدامك لمنصة صناعة، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا لم توافق على أي من هذه الشروط، يرجى عدم استخدام المنصة.'),
              _Section('٢. الأهلية',
                  'يجب أن يكون عمرك ١٨ عاماً أو أكثر لاستخدام المنصة. بالتسجيل، تؤكد أنك تستوفي هذا الشرط.'),
              _Section('٣. حسابات المستخدمين',
                  'أنت مسؤول عن الحفاظ على سرية معلومات حسابك وعن جميع الأنشطة التي تتم من خلاله. يجب إبلاغنا فوراً عن أي استخدام غير مصرح به.'),
              _Section('٤. قواعد السوق',
                  'يجب أن تكون جميع المنتجات المعروضة حقيقية ومطابقة للوصف. يحظر بيع المنتجات المحظورة قانونياً. يحق لنا إزالة أي منتج أو تعليق أي حساب يخالف هذه القواعد.'),
              _Section('٥. التقييمات والمراجعات',
                  'يجب أن تكون التقييمات صادقة وموضوعية. يحظر نشر تقييمات مزيفة أو تشهيرية. يحق لنا إزالة التقييمات التي تخالف سياساتنا.'),
              _Section('٦. الملكية الفكرية',
                  'جميع محتويات المنصة، بما في ذلك التصميم والشعارات والنصوص، هي ملكية خاصة لمنصة صناعة. يحظر نسخها أو إعادة استخدامها دون إذن كتابي.'),
              _Section('٧. إخلاء المسؤولية',
                  'المنصة تعمل كوسيط بين البائعين والمشترين. لا نتحمل مسؤولية جودة المنتجات أو الخلافات بين الأطراف. ننصح المستخدمين بالتحقق من المنتجات قبل الشراء.'),
              _Section('٨. تعليق الحساب',
                  'يحق لنا تعليق أو إنهاء حسابك في حالة مخالفة هذه الشروط، دون إشعار مسبق في الحالات الخطيرة.'),
              _Section('٩. القانون المعمول به',
                  'تخضع هذه الشروط لقوانين الجمهورية اليمنية. أي نزاعات تنشأ عن استخدام المنصة تخضع لاختصاص المحاكم اليمنية.'),
              _Section('١٠. التواصل',
                  'لأي استفسارات حول هذه الشروط، يرجى التواصل معنا عبر صفحة "اتصل بنا" في التطبيق.'),
            ]
          : [
              _Section('1. Acceptance of Terms',
                  'By using the Sinaa platform, you agree to abide by these terms and conditions. If you do not agree to any of these terms, please do not use the platform.'),
              _Section('2. Eligibility',
                  'You must be 18 years of age or older to use the platform. By registering, you confirm that you meet this requirement.'),
              _Section('3. User Accounts',
                  'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You must notify us immediately of any unauthorized use.'),
              _Section('4. Marketplace Rules',
                  'All listed products must be genuine and match their descriptions. Selling legally prohibited products is forbidden. We reserve the right to remove any product or suspend any account that violates these rules.'),
              _Section('5. Ratings and Reviews',
                  'Ratings must be honest and objective. Publishing fake or defamatory reviews is prohibited. We reserve the right to remove reviews that violate our policies.'),
              _Section('6. Intellectual Property',
                  'All platform content, including design, logos, and text, is the property of Sinaa. Copying or reusing without written permission is prohibited.'),
              _Section('7. Disclaimer',
                  'The platform acts as an intermediary between sellers and buyers. We are not responsible for product quality or disputes between parties. Users are advised to verify products before purchase.'),
              _Section('8. Account Suspension',
                  'We reserve the right to suspend or terminate your account for violation of these terms, without prior notice in serious cases.'),
              _Section('9. Governing Law',
                  'These terms are governed by the laws of the Republic of Yemen. Any disputes arising from the use of the platform are subject to the jurisdiction of Yemeni courts.'),
              _Section('10. Contact',
                  'For any inquiries about these terms, please reach out to us through the "Contact Us" page in the app.'),
            ];
    }

    return SliverList(
      delegate: SliverChildListDelegate(
        sections
            .map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          section.body,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.7,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}
