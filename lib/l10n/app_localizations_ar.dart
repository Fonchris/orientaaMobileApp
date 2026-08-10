// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabSearch => 'البحث';

  @override
  String get tabMessages => 'الرسائل';

  @override
  String get tabProfile => 'الملف الشخصي';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String get recommendedUniversities => 'الجامعات الموصى بها';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get noRecommendationsTitle => 'لا توجد توصيات بعد';

  @override
  String get noRecommendationsMessage =>
      'ستظهر الجامعات المطابقة لملفك هنا بمجرد إطلاق كتالوج الاكتشاف.';

  @override
  String get counsellorSession => 'جلسة المستشار';

  @override
  String get noSessionsScheduled => 'لا توجد جلسات مجدولة';

  @override
  String get noUpcomingSessions => 'لا توجد جلسات قادمة';

  @override
  String get sessionsCounsellorEmpty =>
      'ستظهر الجلسات التي تحجزها مع الطلاب هنا.';

  @override
  String get sessionsStudentEmpty =>
      'احجز جلسة مع مستشار وستظهر هنا حتى لا تفوتها أبداً.';

  @override
  String get upcoming => 'قادم';

  @override
  String get booked => 'محجوز';

  @override
  String get suggestedClassrooms => 'الفصول المقترحة';

  @override
  String get noClassroomsYet => 'لا توجد فصول بعد';

  @override
  String get noClassroomsMessage => 'ستُقترح هنا الفصول المطابقة لاهتماماتك.';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get nothingNewYet => 'لا شيء جديد بعد';

  @override
  String get activityMessage =>
      'سيظهر هنا نشاط الأشخاص الذين تتابعهم — منشورات جديدة ومتابعات وتحديثات جلسات.';

  @override
  String get searchTitle => 'البحث';

  @override
  String get searchHint => 'ابحث عن أشخاص وجامعات وفصول...';

  @override
  String get clear => 'مسح';

  @override
  String get recentSearches => 'عمليات البحث الأخيرة';

  @override
  String get suggestedSearches => 'عمليات بحث مقترحة';

  @override
  String get trendingSearches => 'رائجة الآن';

  @override
  String get nothingHereYet => 'لا شيء هنا بعد';

  @override
  String get tabPeople => 'الأشخاص';

  @override
  String get tabUniversities => 'الجامعات';

  @override
  String get tabClassrooms => 'الفصول';

  @override
  String get tabPosts => 'المنشورات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterStudents => 'الطلاب';

  @override
  String get filterCounsellors => 'المستشارون';

  @override
  String get noUniversitiesFound => 'لم يتم العثور على جامعات';

  @override
  String get noClassroomsFound => 'لم يتم العثور على فصول';

  @override
  String noPeopleFound(String query) {
    return 'لم يتم العثور على أشخاص لـ \"$query\"';
  }

  @override
  String noPostsFound(String query) {
    return 'لم يتم العثور على منشورات لـ \"$query\"';
  }

  @override
  String get tryDifferentKeyword =>
      'جرّب كلمة مفتاحية مختلفة أو تحقق من الإملاء.';

  @override
  String get roleStudent => 'طالب';

  @override
  String get roleCounsellor => 'مستشار';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get profileNotFound => 'الملف غير موجود';

  @override
  String get profileNotFoundMessage => 'ربما حذف هذا المستخدم حسابه.';

  @override
  String get couldNotLoadProfile => 'تعذّر تحميل هذا الملف';

  @override
  String get editProfile => 'تعديل الملف';

  @override
  String get share => 'مشاركة';

  @override
  String get follow => 'متابعة';

  @override
  String get following => 'تتابع';

  @override
  String get message => 'رسالة';

  @override
  String get profileLinkCopied => 'تم نسخ رابط الملف';

  @override
  String get fullProfileDetails => 'تفاصيل الملف الكاملة';

  @override
  String get sectionAcademic => 'أكاديمي';

  @override
  String get labelEducationLevel => 'المستوى التعليمي';

  @override
  String get labelDesiredDegree => 'الدرجة المطلوبة';

  @override
  String get labelFieldsOfInterest => 'مجالات الاهتمام';

  @override
  String get labelPlannedStart => 'البدء المخطط';

  @override
  String get sectionLocationLogistics => 'الموقع والخدمات اللوجستية';

  @override
  String get labelHome => 'الوطن';

  @override
  String get labelStudyDestinations => 'وجهات الدراسة';

  @override
  String get labelLanguageOfInstruction => 'لغة التدريس';

  @override
  String get sectionFinancial => 'المالية';

  @override
  String get labelAnnualBudget => 'الميزانية السنوية';

  @override
  String get labelHouseholdIncome => 'دخل الأسرة';

  @override
  String get labelScholarships => 'المنح الدراسية';

  @override
  String get seekingScholarship => 'أبحث عن معلومات المنح';

  @override
  String get notSeekingScholarship => 'لا أبحث حالياً';

  @override
  String get sectionAssessment => 'التقييم';

  @override
  String get labelCareerGoal => 'الهدف المهني';

  @override
  String get labelStrengths => 'نقاط القوة';

  @override
  String get labelInterests => 'الاهتمامات';

  @override
  String get labelGpa => 'المعدل التراكمي';

  @override
  String get labelTestScores => 'درجات الاختبارات';

  @override
  String get addBioPrompt =>
      'أضف نبذة قصيرة ليتعرف عليك الطلاب والمستشارون بشكل أفضل.';

  @override
  String get add => 'إضافة';

  @override
  String get about => 'نبذة';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get readMore => 'قراءة المزيد';

  @override
  String get changeProfilePhoto => 'تغيير صورة الملف';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get uploadingPhoto => 'جارٍ رفع الصورة...';

  @override
  String get photoUpdated => 'تم تحديث صورة الملف';

  @override
  String photoUploadFailed(String error) {
    return 'تعذّر رفع الصورة: $error';
  }

  @override
  String get photoPermissionDenied =>
      'تم رفض الوصول إلى الصور. اسمح بذلك في إعدادات الجهاز ثم أعد المحاولة.';

  @override
  String get statFollowers => 'المتابعون';

  @override
  String get statFollowing => 'يتابع';

  @override
  String get statPosts => 'المنشورات';

  @override
  String get roleVerifiedCounsellor => 'مستشار موثّق';

  @override
  String get academicProfile => 'الملف الأكاديمي';

  @override
  String get fullDetails => 'التفاصيل الكاملة';

  @override
  String get labelEducation => 'التعليم';

  @override
  String get labelDegreeGoal => 'الدرجة المطلوبة';

  @override
  String get labelFieldOfInterest => 'مجال الاهتمام';

  @override
  String savedUniversityOne(int count) {
    return '$count جامعة محفوظة';
  }

  @override
  String savedUniversityMany(int count) {
    return '$count جامعات محفوظة';
  }

  @override
  String get saveUniversitiesCta => 'احفظ الجامعات لبناء قائمتك المختصرة';

  @override
  String get postsTitle => 'المنشورات';

  @override
  String get shareYourJourney => 'شارك رحلتك';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد';

  @override
  String get postsJourneyMessage =>
      'ستظهر هنا المنشورات عن رحلتك في الدراسة بالخارج.';

  @override
  String get studentNoPostsMessage => 'لم ينشر هذا الطالب أي شيء بعد.';

  @override
  String get writeFirstPost => 'اكتب منشورك الأول';

  @override
  String get postOptions => 'خيارات المنشور';

  @override
  String get editPost => 'تعديل المنشور';

  @override
  String get whatOnYourMind => 'ما الذي يدور في ذهنك؟';

  @override
  String get deletePostTitle => 'حذف المنشور؟';

  @override
  String get cannotUndo => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String couldNotUpdateLike(String error) {
    return 'تعذّر تحديث الإعجاب: $error';
  }

  @override
  String couldNotSaveChanges(String error) {
    return 'تعذّر حفظ التغييرات: $error';
  }

  @override
  String couldNotDeletePost(String error) {
    return 'تعذّر حذف المنشور: $error';
  }

  @override
  String get noFollowersYet => 'لا يوجد متابعون بعد';

  @override
  String get notFollowingAnyone => 'لا تتابع أحداً بعد';

  @override
  String get followersEmptyMessage =>
      'عندما يتابعك الطلاب والمستشارون، سيظهرون هنا.';

  @override
  String get followingEmptyMessage =>
      'تابع الطلاب والمستشارين لرؤية نشاطهم في خلاصتك.';

  @override
  String get profileUpdated => 'تم تحديث الملف بنجاح';

  @override
  String couldNotSaveProfile(String error) {
    return 'تعذّر حفظ ملفك: $error';
  }

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get bioTooLong => 'يجب ألا تتجاوز النبذة 250 حرفاً';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get labelFullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'مثال: آدا لافليس';

  @override
  String get labelCountry => 'البلد';

  @override
  String get tapToSelectCountry => 'اضغط لاختيار بلدك';

  @override
  String get labelCity => 'المدينة';

  @override
  String get cityHint => 'مثال: لاغوس';

  @override
  String get labelBio => 'النبذة';

  @override
  String get bioHint => 'مثال: مهندسة برمجيات طموحة شغوفة بالطاقة المتجددة';

  @override
  String get academicInformation => 'المعلومات الأكاديمية';

  @override
  String get yourCustomField => 'مجالك المخصص';

  @override
  String get customFieldHint => 'أدخل مجال اهتمامك...';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get noProfileFound => 'لم يتم العثور على ملف';

  @override
  String get completeOnboardingFirst =>
      'أكمل خطوات التسجيل أولاً ليكون لديك ملف للتعديل.';

  @override
  String get completeMyProfile => 'إكمال ملفي';

  @override
  String get couldNotLoadYourProfile => 'تعذّر تحميل ملفك';

  @override
  String get accountSection => 'الحساب';

  @override
  String get labelEmail => 'البريد الإلكتروني';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get passwordResetHint => 'سنرسل لك رابط إعادة تعيين عبر البريد';

  @override
  String get linkedGoogle => 'حساب Google المرتبط';

  @override
  String get linked => 'مرتبط';

  @override
  String get notLinked => 'غير مرتبط';

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get settingNewFollowers => 'متابعون جدد';

  @override
  String get settingMessages => 'الرسائل';

  @override
  String get settingClassroomActivity => 'نشاط الفصول';

  @override
  String get settingBookingReminders => 'تذكيرات الحجز';

  @override
  String get languageSection => 'اللغة';

  @override
  String get languagePreference => 'اللغة المفضلة';

  @override
  String get privacySection => 'الخصوصية';

  @override
  String get whoCanMessageYou => 'من يمكنه مراسلتك';

  @override
  String get everyone => 'الجميع';

  @override
  String get followersOnly => 'المتابعون فقط';

  @override
  String get showSavedUniversities => 'إظهار جامعاتي المحفوظة';

  @override
  String get accountActions => 'إجراءات الحساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutHint => 'تسجيل الخروج من هذا الجهاز';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountHint => 'إزالة ملفك وبياناتك نهائياً';

  @override
  String get dataSafetyNote =>
      'تحافظ Orientaa على أمان بياناتك. حذف الحساب نهائي.';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور؟';

  @override
  String resetPasswordMessage(String email) {
    return 'سنرسل رابط إعادة التعيين إلى $email.';
  }

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String passwordResetSent(String email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email';
  }

  @override
  String couldNotSendReset(String error) {
    return 'تعذّر إرسال رابط إعادة التعيين: $error';
  }

  @override
  String get noEmailOnAccount => 'لا يوجد بريد إلكتروني على هذا الحساب';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmMessage =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى ملفك.';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get deleteAccountConfirmTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountConfirmMessage =>
      'سيؤدي هذا إلى إزالة ملفك ومنشوراتك وإعداداتك نهائياً. اكتب بريدك الإلكتروني للتأكيد:';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get emailDoesNotMatch => 'البريد الإلكتروني غير متطابق';

  @override
  String get requiresRecentLogin =>
      'يرجى تسجيل الدخول مرة أخرى ثم إعادة محاولة حذف الحساب.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'تعذّر حذف الحساب: $error';
  }

  @override
  String couldNotSaveSetting(String error) {
    return 'تعذّر حفظ الإعداد: $error';
  }

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get themePreference => 'المظهر';

  @override
  String get themeSystem => 'إعدادات النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get startConversationPrompt => 'ابدأ محادثة مع طالب أو مستشار.';

  @override
  String get you => 'أنت';

  @override
  String get messagesPrivacyBlocked =>
      'يقبل هذا المستخدم الرسائل من الأشخاص الذين يتابعهم فقط.';

  @override
  String get searchUsersHint => 'ابحث عن الطلاب والمستشارين...';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get searchByNamePrompt => 'ابحث بالاسم لبدء محادثة';

  @override
  String get counsellorSessionChip => 'جلسة المستشار';

  @override
  String sayHello(String name) {
    return 'قل مرحباً لـ $name!';
  }

  @override
  String get conversationStart => 'هذه بداية محادثتك.';

  @override
  String get writeMessage => 'اكتب رسالة...';

  @override
  String couldNotSendMessage(String error) {
    return 'تعذّر إرسال الرسالة: $error';
  }

  @override
  String get newPost => 'منشور جديد';

  @override
  String get postHint => 'ما الذي يدور في ذهنك؟';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get removeImage => 'إزالة الصورة';

  @override
  String get publishPost => 'نشر';

  @override
  String get posting => 'جارٍ النشر...';

  @override
  String get postPublished => 'تم نشر منشورك.';

  @override
  String couldNotPublishPost(String error) {
    return 'تعذّر نشر منشورك: $error';
  }

  @override
  String get writeSomethingFirst => 'اكتب شيئاً قبل النشر.';

  @override
  String uploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get next => 'التالي';

  @override
  String get toggleTheme => 'تبديل المظهر';

  @override
  String get continueAction => 'متابعة';

  @override
  String get welcomeTitle => 'مرحباً بك في أورينتا';

  @override
  String get welcomeSubtitle => 'مسيرتك المهنية. مستقبلك.';

  @override
  String get welcomeChipExplore => 'استكشف';

  @override
  String get welcomeChipCompare => 'قارن';

  @override
  String get welcomeChipGetMatched => 'احصل على تطابق';

  @override
  String get welcomeFindPathTitle => 'اعثر على طريقك';

  @override
  String get welcomeFindPathSubtitle =>
      'اكتشف الجامعات والبرامج والمنح الدراسية في إفريقيا والعالم — مصمّمة خصيصاً لك.';

  @override
  String get welcomeReadyTitle => 'مستعد للبدء؟';

  @override
  String get welcomeReadySubtitle =>
      'أنشئ حسابك في دقائق وابدأ باستكشاف الفرص المبنية حول أهدافك.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get alreadyHaveAccountLogin => 'لديّ حساب بالفعل — تسجيل الدخول';

  @override
  String get onboardingWelcomeTitle => 'مرحباً أيها المستكشف!';

  @override
  String get onboardingWelcomeSubtitle =>
      'أجب عن بعض الأسئلة وسيرسم أورينتا طريقك نحو الدراسة في أي مكان في العالم.';

  @override
  String get onboardingChipTailored => 'مطابقات مخصصة';

  @override
  String get onboardingChipScholarships => 'منح دراسية';

  @override
  String get onboardingChipExpert => 'إرشاد الخبراء';

  @override
  String get howWillYouUse => 'كيف ستستخدم أورينتا؟';

  @override
  String get pickRoleSubtitle => 'اختر دورك لتخصيص تجربتك';

  @override
  String get selectRoleToContinue => 'اختر دوراً للمتابعة';

  @override
  String get roleStudentDescription =>
      'استكشف الجامعات والبرامج والمنح الدراسية وأدر مسيرتك الأكاديمية.';

  @override
  String get roleCounsellorDescription =>
      'أرشد الطلاب وأدر جلسات الإرشاد ودعم نجاحهم التعليمي.';

  @override
  String selectRoleSemantics(String role) {
    return 'اختر دور $role';
  }

  @override
  String get loginWelcomeBack => 'مرحباً بعودتك!';

  @override
  String get loginSubtitle => 'سجّل الدخول لمواصلة مسيرتك';

  @override
  String get labelPassword => 'كلمة المرور';

  @override
  String get enterValidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get passwordMinLength => 'يجب ألا تقل كلمة المرور عن 6 أحرف';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get sendSignInLinkPasswordless =>
      'إرسال رابط تسجيل الدخول (بدون كلمة مرور)';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get continueWithGoogle => 'المتابعة عبر Google';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get resendVerificationEmail => 'إعادة إرسال بريد التحقق';

  @override
  String get pleaseEnterEmailToComplete =>
      'يرجى إدخال بريدك الإلكتروني لإكمال تسجيل الدخول.';

  @override
  String get signedInWithEmailLink =>
      'تم تسجيل الدخول بنجاح عبر رابط البريد الإلكتروني.';

  @override
  String emailLinkSignInFailed(String error) {
    return 'فشل تسجيل الدخول عبر رابط البريد الإلكتروني: $error';
  }

  @override
  String get confirmYourEmail => 'تأكيد بريدك الإلكتروني';

  @override
  String signInLinkSent(String email) {
    return 'تم إرسال رابط تسجيل الدخول إلى $email';
  }

  @override
  String get enterValidEmailForLink =>
      'أدخل بريداً إلكترونياً صحيحاً لتلقي رابط تسجيل الدخول';

  @override
  String failedToSendSignInLink(String error) {
    return 'فشل إرسال رابط تسجيل الدخول: $error';
  }

  @override
  String get loginSuccessful => 'تم تسجيل الدخول بنجاح';

  @override
  String emailNotVerified(String email) {
    return 'البريد الإلكتروني غير موثَّق. تم إرسال بريد تحقق جديد إلى $email. يرجى التحقق من صندوق الوارد (ومجلد الرسائل غير المرغوب فيها) والنقر على رابط التحقق.';
  }

  @override
  String get googleSignInSuccessful => 'تم تسجيل الدخول عبر Google بنجاح';

  @override
  String verificationResent(String email) {
    return 'تم إعادة إرسال بريد التحقق إلى $email. يرجى التحقق من صندوق الوارد.';
  }

  @override
  String failedToResendVerification(String error) {
    return 'فشل إعادة إرسال التحقق: $error';
  }

  @override
  String get emailExampleHint => 'you@example.com';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get signupSubtitle => 'ابدأ مسيرتك مع أورينتا';

  @override
  String get enterYourFullName => 'أدخل اسمك الكامل';

  @override
  String get enterAPassword => 'أدخل كلمة مرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmYourPassword => 'قم بتأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String verificationEmailSentTo(String email) {
    return 'تم إرسال بريد التحقق إلى $email. يرجى توثيق بريدك الإلكتروني قبل تسجيل الدخول.';
  }

  @override
  String get resetPasswordHeader => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل رابط إعادة التعيين';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get backToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get resetEmailSent =>
      'تم إرسال بريد إعادة التعيين. تحقق من صندوق الوارد.';
}
