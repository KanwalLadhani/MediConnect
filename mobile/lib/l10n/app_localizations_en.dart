import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MediConnect';

  @override
  String get tagline => 'Healthcare help at your doorstep.';

  @override
  String get continueAsPatient => 'Continue as Patient';

  @override
  String get joinAsHealthWorker => 'Join as Health Worker';

  @override
  String get login => 'Login';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Login with your email to continue.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get continueWithOtp => 'Continue with OTP';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get joinWorkerTitle => 'Join as a health worker';

  @override
  String get createPatientAccount => 'Create patient account';

  @override
  String get workerRegisterSubtitle => 'Create your account, then submit documents for verification.';

  @override
  String get patientRegisterSubtitle => 'Create your account to request doorstep healthcare services.';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get createAccount => 'Create account';

  @override
  String get creating => 'Creating...';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get required => 'Required';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get home => 'Home';

  @override
  String get services => 'Services';

  @override
  String get orders => 'Orders';

  @override
  String get chat => 'Chat';

  @override
  String get chats => 'Chats';

  @override
  String get requests => 'Requests';

  @override
  String get active => 'Active';

  @override
  String get wallet => 'Wallet';

  @override
  String get profile => 'Profile';

  @override
  String get chooseCare => 'Choose care';

  @override
  String get servicesSubtitle => 'Select a home healthcare service and share the patient details.';

  @override
  String get noServices => 'No services are available yet.';

  @override
  String get verifiedDoorstepSupport => 'Verified doorstep healthcare support.';

  @override
  String get noActiveChats => 'No active chats';

  @override
  String get chatHubEmptyMessage => 'Chats open after a worker accepts a service request.';

  @override
  String get patientAccount => 'Patient account';

  @override
  String get workerAccount => 'Health worker account';

  @override
  String get adminAccount => 'Admin account';

  @override
  String get phone => 'Phone';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'Urdu';

  @override
  String get notProvided => 'Not provided';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileSafetyNote => 'Keep your phone number reachable. MediConnect is not an emergency service; urgent symptoms need hospital or emergency care.';

  @override
  String get activeOrders => 'Active orders';

  @override
  String get call => 'Call';

  @override
  String get reportIssue => 'Report issue';

  @override
  String get noActiveOrders => 'No active orders';

  @override
  String get noActiveOrdersSubtitle => 'Accepted services will appear here with chat, call, and status details.';

  @override
  String get phoneUnavailable => 'Phone number is not available yet.';

  @override
  String callingUnavailableCopied(Object phone) {
    return 'Calling is not available here. Copied $phone';
  }

  @override
  String get authProviderSetupPending => 'Phone OTP and Google login need Supabase provider setup before they can be used.';

  @override
  String get patientDashboardTitle => 'Book basic healthcare at home';

  @override
  String get patientDashboardSubtitle => 'Choose a service, share your address, then send the request to a verified nearby worker.';

  @override
  String get history => 'History';

  @override
  String get currentService => 'Current service';

  @override
  String get noCurrentService => 'No current service';

  @override
  String get noCurrentServiceSubtitle => 'Accepted services will appear here as soon as a worker confirms.';

  @override
  String get latestService => 'Latest service';

  @override
  String get noServiceHistoryYet => 'No service history yet';

  @override
  String get noServiceHistorySubtitle => 'Completed, cancelled, and disputed services will appear here.';

  @override
  String get emergencySafetyCopy => 'For urgent chest pain, severe bleeding, breathing difficulty, or unconsciousness, go directly to a hospital or emergency service.';

  @override
  String get servicesDashboardSubtitle => 'Pick the service that best matches the patient need.';

  @override
  String get tellWorkersNeed => 'Tell workers what you need';

  @override
  String get tellWorkersNeedSubtitle => 'Clear details help the right worker decide quickly and arrive prepared.';

  @override
  String get patientNeed => 'Patient need';

  @override
  String get issueDetails => 'Issue details';

  @override
  String get issueDetailsHint => 'Describe the patient need, timing, or special care notes';

  @override
  String get addOptionalIssuePhoto => 'Add optional issue photo';

  @override
  String get issuePhotoSelected => 'Issue photo selected';

  @override
  String get issuePhotoUseful => 'Useful for wounds, bandages, or reports';

  @override
  String get serviceLocation => 'Service location';

  @override
  String get address => 'Address';

  @override
  String get addressHint => 'House, street, area';

  @override
  String get city => 'City';

  @override
  String get approvedWorkersOnly => 'Only approved workers who offer this service will be shown.';

  @override
  String get findingWorkers => 'Finding workers...';

  @override
  String get findWorkers => 'Find workers';

  @override
  String get availableWorkers => 'Available workers';

  @override
  String get verifiedMatch => 'verified match';

  @override
  String get verifiedMatches => 'verified matches';

  @override
  String get payWorkerDirectly => 'Pay worker directly';

  @override
  String get approvedByMediConnect => 'Approved by MediConnect';

  @override
  String get nearby => 'Nearby';

  @override
  String get etaShort => 'ETA 25-40 min';

  @override
  String get sending => 'Sending...';

  @override
  String get sendRequestToWorker => 'Send request to worker';

  @override
  String get requestAlreadySent => 'Request already sent';

  @override
  String requestSentSnack(Object offerId) {
    return 'Request sent: $offerId';
  }

  @override
  String requestSentToWorker(Object workerName) {
    return 'Request sent to $workerName';
  }

  @override
  String get requestSentDescription => 'You can track the service once the worker accepts it. Use chat and call from active orders after acceptance.';

  @override
  String get openActiveOrders => 'Open active orders';

  @override
  String get backHome => 'Back home';

  @override
  String get noWorkersAvailable => 'No workers available';

  @override
  String get noWorkersSubtitle => 'Try again later or update the service location.';

  @override
  String get incomingRequests => 'Incoming requests';

  @override
  String orderAcceptedSnack(Object orderId) {
    return 'Order accepted: $orderId';
  }

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get noIncomingRequests => 'No incoming requests';

  @override
  String get noIncomingRequestsSubtitle => 'New patient requests will appear here while you are available.';

  @override
  String get availableBalance => 'Available balance';

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get requestWalletTopUpButton => 'Request JazzCash/EasyPaisa top-up';

  @override
  String get transactions => 'Transactions';

  @override
  String get noWalletTransactions => 'No wallet transactions yet.';

  @override
  String get requestWalletTopUp => 'Request wallet top-up';

  @override
  String get amountPkr => 'Amount PKR';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get transactionReference => 'Transaction reference';

  @override
  String get enterTransactionReference => 'Enter the transaction reference';

  @override
  String get attachScreenshot => 'Attach screenshot';

  @override
  String get screenshotAttached => 'Screenshot attached';

  @override
  String get optionalRecommended => 'Optional but recommended';

  @override
  String get submitTopUpRequest => 'Submit top-up request';

  @override
  String get topUpSubmitted => 'Top-up request submitted';

  @override
  String get issueReported => 'Issue reported';

  @override
  String get cancelOrderQuestion => 'Cancel order?';

  @override
  String get cancelOrderWarning => 'Only cancel if the service is no longer needed or the worker cannot continue.';

  @override
  String get keepOrder => 'Keep order';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String patientLabel(Object name) {
    return 'Patient: $name';
  }

  @override
  String workerLabel(Object name) {
    return 'Worker: $name';
  }

  @override
  String activeOrderEmergencyCopy(Object name) {
    return 'For emergencies, contact local emergency services or go to a hospital. Use report issue for service problems with $name.';
  }

  @override
  String get checkingWorkerLocation => 'Checking latest worker location...';

  @override
  String get locationUpdatesPending => 'Location updates will appear here after the worker shares GPS.';

  @override
  String latestLocation(Object latitude, Object longitude, Object time) {
    return 'Latest location: $latitude, $longitude at $time';
  }

  @override
  String updatedAtTime(Object time) {
    return 'Updated $time';
  }

  @override
  String get onWay => 'On way';

  @override
  String get reportIssueTitle => 'Report issue';

  @override
  String get reason => 'Reason';

  @override
  String get details => 'Details';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get serviceHistory => 'Service history';

  @override
  String get reviewSubmitted => 'Review submitted';

  @override
  String get leaveReview => 'Leave review';

  @override
  String get reviewNotes => 'Review notes';

  @override
  String get review => 'Review';

  @override
  String get serviceNotes => 'Service notes';

  @override
  String get workerDashboard => 'Worker dashboard';

  @override
  String get locationShared => 'Location shared';

  @override
  String get completeOrder => 'Complete order';

  @override
  String get finalChargePkr => 'Final charge in PKR';

  @override
  String get completionServiceNotesHint => 'Optional care notes for patient history';

  @override
  String get complete => 'Complete';

  @override
  String verificationStatusValue(Object status) {
    return 'Verification $status';
  }

  @override
  String get workerApprovalRequired => 'Only approved workers can accept service requests.';

  @override
  String get availableForRequests => 'Available for requests';

  @override
  String get availableForRequestsSubtitle => 'Turn on when you are ready to accept nearby services.';

  @override
  String get statWallet => 'Wallet';

  @override
  String get statToday => 'Today';

  @override
  String get statEarnings => 'Earnings';

  @override
  String get statRequests => 'Requests';

  @override
  String get statTotalOrders => 'Total orders';

  @override
  String get statRating => 'Rating';

  @override
  String get viewIncomingRequests => 'View incoming requests';

  @override
  String viewRequestCount(Object count) {
    return 'View $count request(s)';
  }

  @override
  String get openWallet => 'Open wallet';

  @override
  String get viewOrderHistory => 'View order history';

  @override
  String get recentReviews => 'Recent reviews';

  @override
  String get noWorkerReviews => 'Patient reviews will appear here after completed orders.';

  @override
  String get noActiveOrdersNow => 'No active orders right now.';

  @override
  String get markOnTheWay => 'Mark on the way';

  @override
  String get startService => 'Start service';

  @override
  String get completeService => 'Complete service';

  @override
  String get update => 'Update';

  @override
  String get shareLocation => 'Share location';

  @override
  String get openChat => 'Open chat';

  @override
  String get retry => 'Retry';

  @override
  String get orderChatUnavailable => 'This order chat is not available.';

  @override
  String get refresh => 'Refresh';

  @override
  String get attachImage => 'Attach image';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get orderChat => 'Order chat';

  @override
  String imageAttachmentWithName(Object name) {
    return 'Image attachment: $name';
  }

  @override
  String get uploaded => 'uploaded';

  @override
  String get imageCouldNotBeLoaded => 'Image could not be loaded.';

  @override
  String get imageAttachment => 'Image attachment';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get chatGuidance => 'Use chat for service details, photos, and arrival coordination.';

  @override
  String get roleSelectionTitle => 'How will you use MediConnect?';

  @override
  String get roleSelectionSubtitle => 'Choose the account type that matches what you need today.';

  @override
  String get patientRoleTitle => 'Patient';

  @override
  String get patientRoleDescription => 'Request home healthcare services and hire verified workers.';

  @override
  String get workerRoleTitle => 'Health worker';

  @override
  String get workerRoleDescription => 'Offer approved healthcare services after document verification.';

  @override
  String get patientDetails => 'Patient details';

  @override
  String get patientDetailsSubtitle => 'Add the basic details needed to request home healthcare services.';

  @override
  String get cityHint => 'Karachi, Lahore, Islamabad';

  @override
  String get gender => 'Gender';

  @override
  String get emergencyContactPhone => 'Emergency contact phone';

  @override
  String get medicalNotes => 'Medical notes';

  @override
  String get medicalNotesHint => 'Allergies, existing illness, or important details';

  @override
  String get saving => 'Saving...';

  @override
  String get allowLocationAndContinue => 'Allow location and continue';

  @override
  String get workerVerificationTitle => 'Health worker verification';

  @override
  String get workerVerificationSubtitle => 'Submit your qualification, services, and documents. Admin review usually takes 12-24 hours.';

  @override
  String get workerType => 'Worker type';

  @override
  String get doctor => 'Doctor';

  @override
  String get nurse => 'Nurse';

  @override
  String get maleNurse => 'Male nurse';

  @override
  String get otTechnician => 'OT technician';

  @override
  String get dispenser => 'Dispenser';

  @override
  String get labCollector => 'Lab collector';

  @override
  String get other => 'Other';

  @override
  String get qualification => 'Qualification';

  @override
  String get experienceYears => 'Experience years';

  @override
  String get serviceArea => 'Service area';

  @override
  String get primaryService => 'Primary service';

  @override
  String get basePricePkr => 'Base price PKR';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Briefly explain your healthcare experience';

  @override
  String get cnic => 'CNIC';

  @override
  String get cnicUploadSubtitle => 'Upload front/back image or PDF';

  @override
  String get medicalLicenseOrCertificate => 'Medical license or certificate';

  @override
  String get certificateUploadSubtitle => 'Upload proof of qualification';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoSubtitle => 'Optional image for your worker profile';

  @override
  String get missingWorkerDocuments => 'Please select CNIC and qualification documents.';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitForVerification => 'Submit for verification';

  @override
  String get verificationRejected => 'Verification rejected';

  @override
  String get verificationPending => 'Verification pending';

  @override
  String get verificationRejectedSubtitle => 'Please review the admin note and resubmit corrected details.';

  @override
  String get verificationPendingSubtitle => 'Your documents have been submitted. The MediConnect team will review them before you can accept work.';

  @override
  String get adminNote => 'Admin note';

  @override
  String get expectedReviewTime => 'Expected review time';

  @override
  String get workerCorrectionFallback => 'Documents or profile details need correction.';

  @override
  String get workerReviewTimeCopy => 'Most health worker profiles are reviewed within 12-24 hours.';

  @override
  String get resubmitDetails => 'Resubmit details';

  @override
  String get reviewSubmittedDetails => 'Review submitted details';

  @override
  String get pakistanMvp => 'PAKISTAN MVP';

  @override
  String get landingDescription => 'Request verified health workers for basic home services like bandage care, injections, drips, blood samples, and checkups.';

  @override
  String get verifiedWorkers => 'Verified workers';

  @override
  String get cashServicePayment => 'Cash service payment';

  @override
  String get landingEmergencyCopy => 'MediConnect is for basic doorstep healthcare support. For emergencies, go to a hospital or local emergency service.';

  @override
  String get chooseHowToContinue => 'Choose how to continue';

  @override
  String get patientEntrySubtitle => 'Find and request a nearby verified worker.';

  @override
  String get workerEntrySubtitle => 'Submit documents and offer services after approval.';

  @override
  String get notifications => 'Notifications';

  @override
  String get markRead => 'Mark read';

  @override
  String get notificationsEmpty => 'Verification, order, and wallet updates appear here.';
}
