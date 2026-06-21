import 'app_localizations.dart';

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'میڈی کنیکٹ';

  @override
  String get tagline => 'صحت کی سہولت آپ کے دروازے پر۔';

  @override
  String get continueAsPatient => 'مریض کے طور پر جاری رکھیں';

  @override
  String get joinAsHealthWorker => 'ہیلتھ ورکر کے طور پر شامل ہوں';

  @override
  String get login => 'لاگ ان';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get loginSubtitle => 'جاری رکھنے کے لیے ای میل سے لاگ ان کریں۔';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get loggingIn => 'لاگ ان ہو رہا ہے...';

  @override
  String get continueWithOtp => 'او ٹی پی کے ساتھ جاری رکھیں';

  @override
  String get continueWithGoogle => 'گوگل کے ساتھ جاری رکھیں';

  @override
  String get createNewAccount => 'نیا اکاؤنٹ بنائیں';

  @override
  String get joinWorkerTitle => 'ہیلتھ ورکر کے طور پر شامل ہوں';

  @override
  String get createPatientAccount => 'مریض کا اکاؤنٹ بنائیں';

  @override
  String get workerRegisterSubtitle => 'اپنا اکاؤنٹ بنائیں، پھر تصدیق کے لیے دستاویزات جمع کروائیں۔';

  @override
  String get patientRegisterSubtitle => 'گھر پر صحت کی سہولت حاصل کرنے کے لیے اکاؤنٹ بنائیں۔';

  @override
  String get fullName => 'مکمل نام';

  @override
  String get phoneNumber => 'فون نمبر';

  @override
  String get createAccount => 'اکاؤنٹ بنائیں';

  @override
  String get creating => 'بنایا جا رہا ہے...';

  @override
  String get alreadyHaveAccount => 'پہلے سے اکاؤنٹ ہے؟ لاگ ان کریں';

  @override
  String get required => 'ضروری';

  @override
  String get passwordTooShort => 'کم از کم 6 حروف استعمال کریں';

  @override
  String get home => 'ہوم';

  @override
  String get services => 'سروسز';

  @override
  String get orders => 'آرڈرز';

  @override
  String get chat => 'چیٹ';

  @override
  String get chats => 'چیٹس';

  @override
  String get requests => 'درخواستیں';

  @override
  String get active => 'فعال';

  @override
  String get wallet => 'والیٹ';

  @override
  String get profile => 'پروفائل';

  @override
  String get chooseCare => 'سہولت منتخب کریں';

  @override
  String get servicesSubtitle => 'گھر پر صحت کی سہولت منتخب کریں اور مریض کی تفصیل درج کریں۔';

  @override
  String get noServices => 'فی الحال کوئی سروس دستیاب نہیں۔';

  @override
  String get verifiedDoorstepSupport => 'تصدیق شدہ گھر پر صحت کی سہولت۔';

  @override
  String get noActiveChats => 'کوئی فعال چیٹ نہیں';

  @override
  String get chatHubEmptyMessage => 'ورکر کے سروس درخواست قبول کرنے کے بعد چیٹ کھلتی ہے۔';

  @override
  String get patientAccount => 'مریض اکاؤنٹ';

  @override
  String get workerAccount => 'ہیلتھ ورکر اکاؤنٹ';

  @override
  String get adminAccount => 'ایڈمن اکاؤنٹ';

  @override
  String get phone => 'فون';

  @override
  String get language => 'زبان';

  @override
  String get languageEnglish => 'انگریزی';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get notProvided => 'فراہم نہیں کیا گیا';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get profileSafetyNote => 'اپنا فون نمبر قابل رسائی رکھیں۔ میڈی کنیکٹ ایمرجنسی سروس نہیں ہے؛ فوری علامات کے لیے ہسپتال یا ایمرجنسی سروس سے رابطہ کریں۔';

  @override
  String get activeOrders => 'فعال آرڈرز';

  @override
  String get call => 'کال';

  @override
  String get reportIssue => 'مسئلہ رپورٹ کریں';

  @override
  String get noActiveOrders => 'کوئی فعال آرڈر نہیں';

  @override
  String get noActiveOrdersSubtitle => 'قبول شدہ سروسز یہاں چیٹ، کال، اور اسٹیٹس کے ساتھ نظر آئیں گی۔';

  @override
  String get phoneUnavailable => 'فون نمبر ابھی دستیاب نہیں۔';

  @override
  String callingUnavailableCopied(Object phone) {
    return 'یہاں کال دستیاب نہیں۔ $phone کاپی کر دیا گیا';
  }

  @override
  String get authProviderSetupPending => 'فون او ٹی پی اور گوگل لاگ ان استعمال کرنے سے پہلے Supabase provider setup چاہیے۔';

  @override
  String get patientDashboardTitle => 'گھر پر بنیادی صحت کی سہولت بک کریں';

  @override
  String get patientDashboardSubtitle => 'سروس منتخب کریں، اپنا پتہ دیں، پھر قریبی تصدیق شدہ ورکر کو درخواست بھیجیں۔';

  @override
  String get history => 'ہسٹری';

  @override
  String get currentService => 'موجودہ سروس';

  @override
  String get noCurrentService => 'کوئی موجودہ سروس نہیں';

  @override
  String get noCurrentServiceSubtitle => 'ورکر کے قبول کرتے ہی سروس یہاں نظر آئے گی۔';

  @override
  String get latestService => 'تازہ ترین سروس';

  @override
  String get noServiceHistoryYet => 'ابھی کوئی سروس ہسٹری نہیں';

  @override
  String get noServiceHistorySubtitle => 'مکمل، منسوخ، اور disputed سروسز یہاں نظر آئیں گی۔';

  @override
  String get emergencySafetyCopy => 'سینے میں شدید درد، زیادہ خون بہنے، سانس لینے میں دشواری، یا بے ہوشی کی صورت میں فوراً ہسپتال یا ایمرجنسی سروس سے رابطہ کریں۔';

  @override
  String get servicesDashboardSubtitle => 'وہ سروس منتخب کریں جو مریض کی ضرورت کے مطابق ہو۔';

  @override
  String get tellWorkersNeed => 'ورکرز کو بتائیں کہ آپ کو کیا چاہیے';

  @override
  String get tellWorkersNeedSubtitle => 'واضح تفصیل سے درست ورکر جلد فیصلہ کر سکتا ہے اور تیاری کے ساتھ آتا ہے۔';

  @override
  String get patientNeed => 'مریض کی ضرورت';

  @override
  String get issueDetails => 'مسئلے کی تفصیل';

  @override
  String get issueDetailsHint => 'مریض کی ضرورت، وقت، یا خاص دیکھ بھال کی تفصیل لکھیں';

  @override
  String get addOptionalIssuePhoto => 'اختیاری تصویر شامل کریں';

  @override
  String get issuePhotoSelected => 'تصویر منتخب ہو گئی';

  @override
  String get issuePhotoUseful => 'زخم، پٹی، یا رپورٹس کے لیے مفید';

  @override
  String get serviceLocation => 'سروس کا مقام';

  @override
  String get address => 'پتہ';

  @override
  String get addressHint => 'گھر، گلی، علاقہ';

  @override
  String get city => 'شہر';

  @override
  String get approvedWorkersOnly => 'صرف منظور شدہ ورکرز جو یہ سروس دیتے ہیں دکھائے جائیں گے۔';

  @override
  String get findingWorkers => 'ورکرز تلاش ہو رہے ہیں...';

  @override
  String get findWorkers => 'ورکرز تلاش کریں';

  @override
  String get availableWorkers => 'دستیاب ورکرز';

  @override
  String get verifiedMatch => 'تصدیق شدہ میچ';

  @override
  String get verifiedMatches => 'تصدیق شدہ میچز';

  @override
  String get payWorkerDirectly => 'ادائیگی براہ راست ورکر کو کریں';

  @override
  String get approvedByMediConnect => 'MediConnect سے منظور شدہ';

  @override
  String get nearby => 'قریب';

  @override
  String get etaShort => 'تقریباً 25-40 منٹ';

  @override
  String get sending => 'بھیجا جا رہا ہے...';

  @override
  String get sendRequestToWorker => 'ورکر کو درخواست بھیجیں';

  @override
  String get requestAlreadySent => 'درخواست پہلے ہی بھیج دی گئی';

  @override
  String requestSentSnack(Object offerId) {
    return 'درخواست بھیج دی گئی: $offerId';
  }

  @override
  String requestSentToWorker(Object workerName) {
    return '$workerName کو درخواست بھیج دی گئی';
  }

  @override
  String get requestSentDescription => 'ورکر کے قبول کرنے کے بعد آپ سروس کو ٹریک کر سکتے ہیں۔ قبول ہونے کے بعد active orders سے chat اور call استعمال کریں۔';

  @override
  String get openActiveOrders => 'فعال آرڈرز کھولیں';

  @override
  String get backHome => 'واپس ہوم';

  @override
  String get noWorkersAvailable => 'کوئی ورکر دستیاب نہیں';

  @override
  String get noWorkersSubtitle => 'بعد میں دوبارہ کوشش کریں یا سروس کا مقام تبدیل کریں۔';

  @override
  String get incomingRequests => 'آنے والی درخواستیں';

  @override
  String orderAcceptedSnack(Object orderId) {
    return 'آرڈر قبول ہو گیا: $orderId';
  }

  @override
  String get decline => 'انکار کریں';

  @override
  String get accept => 'قبول کریں';

  @override
  String get noIncomingRequests => 'کوئی نئی درخواست نہیں';

  @override
  String get noIncomingRequestsSubtitle => 'جب آپ دستیاب ہوں گے تو مریضوں کی نئی درخواستیں یہاں آئیں گی۔';

  @override
  String get availableBalance => 'دستیاب بیلنس';

  @override
  String statusLabel(Object status) {
    return 'اسٹیٹس: $status';
  }

  @override
  String get requestWalletTopUpButton => 'JazzCash/EasyPaisa ٹاپ اپ درخواست کریں';

  @override
  String get transactions => 'ٹرانزیکشنز';

  @override
  String get noWalletTransactions => 'ابھی کوئی والیٹ ٹرانزیکشن نہیں۔';

  @override
  String get requestWalletTopUp => 'والیٹ ٹاپ اپ درخواست';

  @override
  String get amountPkr => 'رقم PKR';

  @override
  String get enterValidAmount => 'درست رقم درج کریں';

  @override
  String get transactionReference => 'ٹرانزیکشن ریفرنس';

  @override
  String get enterTransactionReference => 'ٹرانزیکشن ریفرنس درج کریں';

  @override
  String get attachScreenshot => 'اسکرین شاٹ لگائیں';

  @override
  String get screenshotAttached => 'اسکرین شاٹ لگ گیا';

  @override
  String get optionalRecommended => 'اختیاری مگر بہتر ہے';

  @override
  String get submitTopUpRequest => 'ٹاپ اپ درخواست جمع کریں';

  @override
  String get topUpSubmitted => 'ٹاپ اپ درخواست جمع ہو گئی';

  @override
  String get issueReported => 'مسئلہ رپورٹ ہو گیا';

  @override
  String get cancelOrderQuestion => 'آرڈر منسوخ کریں؟';

  @override
  String get cancelOrderWarning => 'صرف اس صورت میں منسوخ کریں جب سروس کی ضرورت نہ رہے یا ورکر جاری نہ رکھ سکے۔';

  @override
  String get keepOrder => 'آرڈر برقرار رکھیں';

  @override
  String get cancelOrder => 'آرڈر منسوخ کریں';

  @override
  String get orderCancelled => 'آرڈر منسوخ ہو گیا';

  @override
  String patientLabel(Object name) {
    return 'مریض: $name';
  }

  @override
  String workerLabel(Object name) {
    return 'ورکر: $name';
  }

  @override
  String activeOrderEmergencyCopy(Object name) {
    return 'ایمرجنسی میں مقامی ایمرجنسی سروس یا ہسپتال سے رابطہ کریں۔ $name کے ساتھ سروس کے مسائل کے لیے report issue استعمال کریں۔';
  }

  @override
  String get checkingWorkerLocation => 'ورکر کی تازہ لوکیشن چیک ہو رہی ہے...';

  @override
  String get locationUpdatesPending => 'ورکر کے GPS شیئر کرنے کے بعد لوکیشن اپ ڈیٹس یہاں نظر آئیں گی۔';

  @override
  String latestLocation(Object latitude, Object longitude, Object time) {
    return 'تازہ لوکیشن: $latitude, $longitude وقت $time';
  }

  @override
  String updatedAtTime(Object time) {
    return 'اپ ڈیٹ $time';
  }

  @override
  String get onWay => 'راستے میں';

  @override
  String get reportIssueTitle => 'مسئلہ رپورٹ کریں';

  @override
  String get reason => 'وجہ';

  @override
  String get details => 'تفصیل';

  @override
  String get cancel => 'منسوخ';

  @override
  String get submit => 'جمع کریں';

  @override
  String get serviceHistory => 'سروس ہسٹری';

  @override
  String get reviewSubmitted => 'ریویو جمع ہو گیا';

  @override
  String get leaveReview => 'ریویو دیں';

  @override
  String get reviewNotes => 'ریویو نوٹس';

  @override
  String get review => 'ریویو';

  @override
  String get serviceNotes => 'سروس نوٹس';

  @override
  String get workerDashboard => 'ورکر ڈیش بورڈ';

  @override
  String get locationShared => 'لوکیشن شیئر ہو گئی';

  @override
  String get completeOrder => 'آرڈر مکمل کریں';

  @override
  String get finalChargePkr => 'حتمی چارج PKR میں';

  @override
  String get completionServiceNotesHint => 'مریض کی ہسٹری کے لیے اختیاری دیکھ بھال نوٹس';

  @override
  String get complete => 'مکمل کریں';

  @override
  String verificationStatusValue(Object status) {
    return 'ویریفکیشن $status';
  }

  @override
  String get workerApprovalRequired => 'صرف منظور شدہ ورکرز سروس درخواستیں قبول کر سکتے ہیں۔';

  @override
  String get availableForRequests => 'درخواستوں کے لیے دستیاب';

  @override
  String get availableForRequestsSubtitle => 'جب آپ قریبی سروسز قبول کرنے کے لیے تیار ہوں تو آن کریں۔';

  @override
  String get statWallet => 'والیٹ';

  @override
  String get statToday => 'آج';

  @override
  String get statEarnings => 'آمدنی';

  @override
  String get statRequests => 'درخواستیں';

  @override
  String get statTotalOrders => 'کل آرڈرز';

  @override
  String get statRating => 'ریٹنگ';

  @override
  String get viewIncomingRequests => 'آنے والی درخواستیں دیکھیں';

  @override
  String viewRequestCount(Object count) {
    return '$count درخواستیں دیکھیں';
  }

  @override
  String get openWallet => 'والیٹ کھولیں';

  @override
  String get viewOrderHistory => 'آرڈر ہسٹری دیکھیں';

  @override
  String get recentReviews => 'حالیہ ریویوز';

  @override
  String get noWorkerReviews => 'مکمل آرڈرز کے بعد مریضوں کے ریویوز یہاں نظر آئیں گے۔';

  @override
  String get noActiveOrdersNow => 'ابھی کوئی فعال آرڈر نہیں۔';

  @override
  String get markOnTheWay => 'راستے میں مارک کریں';

  @override
  String get startService => 'سروس شروع کریں';

  @override
  String get completeService => 'سروس مکمل کریں';

  @override
  String get update => 'اپ ڈیٹ';

  @override
  String get shareLocation => 'لوکیشن شیئر کریں';

  @override
  String get openChat => 'چیٹ کھولیں';

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String get orderChatUnavailable => 'اس آرڈر کی چیٹ دستیاب نہیں۔';

  @override
  String get refresh => 'ریفریش';

  @override
  String get attachImage => 'تصویر لگائیں';

  @override
  String get message => 'پیغام';

  @override
  String get send => 'بھیجیں';

  @override
  String get orderChat => 'آرڈر چیٹ';

  @override
  String imageAttachmentWithName(Object name) {
    return 'تصویر اٹیچمنٹ: $name';
  }

  @override
  String get uploaded => 'اپ لوڈ شدہ';

  @override
  String get imageCouldNotBeLoaded => 'تصویر لوڈ نہیں ہو سکی۔';

  @override
  String get imageAttachment => 'تصویر اٹیچمنٹ';

  @override
  String get noMessagesYet => 'ابھی کوئی پیغام نہیں';

  @override
  String get chatGuidance => 'سروس کی تفصیل، تصاویر، اور آمد کی کوآرڈینیشن کے لیے چیٹ استعمال کریں۔';

  @override
  String get roleSelectionTitle => 'آپ MediConnect کیسے استعمال کریں گے؟';

  @override
  String get roleSelectionSubtitle => 'وہ اکاؤنٹ ٹائپ منتخب کریں جو آج آپ کی ضرورت سے میل کھاتا ہو۔';

  @override
  String get patientRoleTitle => 'مریض';

  @override
  String get patientRoleDescription => 'گھر پر ہیلتھ کیئر سروسز کی درخواست کریں اور تصدیق شدہ ورکرز کو ہائر کریں۔';

  @override
  String get workerRoleTitle => 'ہیلتھ ورکر';

  @override
  String get workerRoleDescription => 'دستاویزات کی تصدیق کے بعد منظور شدہ ہیلتھ کیئر سروسز فراہم کریں۔';

  @override
  String get patientDetails => 'مریض کی تفصیلات';

  @override
  String get patientDetailsSubtitle => 'گھر پر ہیلتھ کیئر سروسز کی درخواست کے لیے بنیادی تفصیلات شامل کریں۔';

  @override
  String get cityHint => 'کراچی، لاہور، اسلام آباد';

  @override
  String get gender => 'جنس';

  @override
  String get emergencyContactPhone => 'ایمرجنسی رابطہ فون';

  @override
  String get medicalNotes => 'میڈیکل نوٹس';

  @override
  String get medicalNotesHint => 'الرجی، موجودہ بیماری، یا اہم تفصیلات';

  @override
  String get saving => 'محفوظ ہو رہا ہے...';

  @override
  String get allowLocationAndContinue => 'لوکیشن کی اجازت دیں اور جاری رکھیں';

  @override
  String get workerVerificationTitle => 'ہیلتھ ورکر ویریفکیشن';

  @override
  String get workerVerificationSubtitle => 'اپنی اہلیت، سروسز، اور دستاویزات جمع کریں۔ ایڈمن ریویو عموماً 12-24 گھنٹے لیتا ہے۔';

  @override
  String get workerType => 'ورکر ٹائپ';

  @override
  String get doctor => 'ڈاکٹر';

  @override
  String get nurse => 'نرس';

  @override
  String get maleNurse => 'میل نرس';

  @override
  String get otTechnician => 'OT ٹیکنیشن';

  @override
  String get dispenser => 'ڈسپنسر';

  @override
  String get labCollector => 'لیب کلیکٹر';

  @override
  String get other => 'دیگر';

  @override
  String get qualification => 'اہلیت';

  @override
  String get experienceYears => 'تجربے کے سال';

  @override
  String get serviceArea => 'سروس ایریا';

  @override
  String get primaryService => 'بنیادی سروس';

  @override
  String get basePricePkr => 'بنیادی قیمت PKR';

  @override
  String get enterValidPrice => 'درست قیمت درج کریں';

  @override
  String get bio => 'بائیو';

  @override
  String get bioHint => 'اپنے ہیلتھ کیئر تجربے کی مختصر وضاحت کریں';

  @override
  String get cnic => 'CNIC';

  @override
  String get cnicUploadSubtitle => 'فرنٹ/بیک تصویر یا PDF اپ لوڈ کریں';

  @override
  String get medicalLicenseOrCertificate => 'میڈیکل لائسنس یا سرٹیفکیٹ';

  @override
  String get certificateUploadSubtitle => 'اہلیت کا ثبوت اپ لوڈ کریں';

  @override
  String get profilePhoto => 'پروفائل تصویر';

  @override
  String get profilePhotoSubtitle => 'آپ کے ورکر پروفائل کے لیے اختیاری تصویر';

  @override
  String get missingWorkerDocuments => 'براہ کرم CNIC اور اہلیت کی دستاویزات منتخب کریں۔';

  @override
  String get submitting => 'جمع ہو رہا ہے...';

  @override
  String get submitForVerification => 'ویریفکیشن کے لیے جمع کریں';

  @override
  String get verificationRejected => 'ویریفکیشن مسترد';

  @override
  String get verificationPending => 'ویریفکیشن زیر التوا';

  @override
  String get verificationRejectedSubtitle => 'ایڈمن نوٹ دیکھیں اور درست تفصیلات دوبارہ جمع کریں۔';

  @override
  String get verificationPendingSubtitle => 'آپ کی دستاویزات جمع ہو چکی ہیں۔ MediConnect ٹیم کام قبول کرنے سے پہلے ان کا ریویو کرے گی۔';

  @override
  String get adminNote => 'ایڈمن نوٹ';

  @override
  String get expectedReviewTime => 'متوقع ریویو وقت';

  @override
  String get workerCorrectionFallback => 'دستاویزات یا پروفائل تفصیلات درست کرنے کی ضرورت ہے۔';

  @override
  String get workerReviewTimeCopy => 'زیادہ تر ہیلتھ ورکر پروفائلز 12-24 گھنٹوں میں ریویو ہو جاتے ہیں۔';

  @override
  String get resubmitDetails => 'تفصیلات دوبارہ جمع کریں';

  @override
  String get reviewSubmittedDetails => 'جمع شدہ تفصیلات دیکھیں';

  @override
  String get pakistanMvp => 'پاکستان MVP';

  @override
  String get landingDescription => 'بینڈیج کی دیکھ بھال، انجیکشن، ڈرپ، خون کے نمونے، اور چیک اپ جیسی بنیادی گھریلو سروسز کے لیے تصدیق شدہ ہیلتھ ورکرز کی درخواست کریں۔';

  @override
  String get verifiedWorkers => 'تصدیق شدہ ورکرز';

  @override
  String get cashServicePayment => 'کیش سروس ادائیگی';

  @override
  String get landingEmergencyCopy => 'MediConnect بنیادی گھریلو ہیلتھ کیئر سپورٹ کے لیے ہے۔ ایمرجنسی میں ہسپتال یا مقامی ایمرجنسی سروس سے رابطہ کریں۔';

  @override
  String get chooseHowToContinue => 'جاری رکھنے کا طریقہ منتخب کریں';

  @override
  String get patientEntrySubtitle => 'قریبی تصدیق شدہ ورکر تلاش کریں اور درخواست بھیجیں۔';

  @override
  String get workerEntrySubtitle => 'دستاویزات جمع کریں اور منظوری کے بعد سروسز فراہم کریں۔';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get markRead => 'پڑھا ہوا کریں';

  @override
  String get notificationsEmpty => 'ویریفکیشن، آرڈر، اور والیٹ اپ ڈیٹس یہاں نظر آئیں گی۔';
}
