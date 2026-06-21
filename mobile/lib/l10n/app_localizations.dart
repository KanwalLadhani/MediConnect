import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MediConnect'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Healthcare help at your doorstep.'**
  String get tagline;

  /// No description provided for @continueAsPatient.
  ///
  /// In en, this message translates to:
  /// **'Continue as Patient'**
  String get continueAsPatient;

  /// No description provided for @joinAsHealthWorker.
  ///
  /// In en, this message translates to:
  /// **'Join as Health Worker'**
  String get joinAsHealthWorker;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login with your email to continue.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @continueWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Continue with OTP'**
  String get continueWithOtp;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccount;

  /// No description provided for @joinWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Join as a health worker'**
  String get joinWorkerTitle;

  /// No description provided for @createPatientAccount.
  ///
  /// In en, this message translates to:
  /// **'Create patient account'**
  String get createPatientAccount;

  /// No description provided for @workerRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account, then submit documents for verification.'**
  String get workerRegisterSubtitle;

  /// No description provided for @patientRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to request doorstep healthcare services.'**
  String get patientRegisterSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @chooseCare.
  ///
  /// In en, this message translates to:
  /// **'Choose care'**
  String get chooseCare;

  /// No description provided for @servicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a home healthcare service and share the patient details.'**
  String get servicesSubtitle;

  /// No description provided for @noServices.
  ///
  /// In en, this message translates to:
  /// **'No services are available yet.'**
  String get noServices;

  /// No description provided for @verifiedDoorstepSupport.
  ///
  /// In en, this message translates to:
  /// **'Verified doorstep healthcare support.'**
  String get verifiedDoorstepSupport;

  /// No description provided for @noActiveChats.
  ///
  /// In en, this message translates to:
  /// **'No active chats'**
  String get noActiveChats;

  /// No description provided for @chatHubEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Chats open after a worker accepts a service request.'**
  String get chatHubEmptyMessage;

  /// No description provided for @patientAccount.
  ///
  /// In en, this message translates to:
  /// **'Patient account'**
  String get patientAccount;

  /// No description provided for @workerAccount.
  ///
  /// In en, this message translates to:
  /// **'Health worker account'**
  String get workerAccount;

  /// No description provided for @adminAccount.
  ///
  /// In en, this message translates to:
  /// **'Admin account'**
  String get adminAccount;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @profileSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone number reachable. MediConnect is not an emergency service; urgent symptoms need hospital or emergency care.'**
  String get profileSafetyNote;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active orders'**
  String get activeOrders;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssue;

  /// No description provided for @noActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'No active orders'**
  String get noActiveOrders;

  /// No description provided for @noActiveOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accepted services will appear here with chat, call, and status details.'**
  String get noActiveOrdersSubtitle;

  /// No description provided for @phoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number is not available yet.'**
  String get phoneUnavailable;

  /// No description provided for @callingUnavailableCopied.
  ///
  /// In en, this message translates to:
  /// **'Calling is not available here. Copied {phone}'**
  String callingUnavailableCopied(Object phone);

  /// No description provided for @authProviderSetupPending.
  ///
  /// In en, this message translates to:
  /// **'Phone OTP and Google login need Supabase provider setup before they can be used.'**
  String get authProviderSetupPending;

  /// No description provided for @patientDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Book basic healthcare at home'**
  String get patientDashboardTitle;

  /// No description provided for @patientDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a service, share your address, then send the request to a verified nearby worker.'**
  String get patientDashboardSubtitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @currentService.
  ///
  /// In en, this message translates to:
  /// **'Current service'**
  String get currentService;

  /// No description provided for @noCurrentService.
  ///
  /// In en, this message translates to:
  /// **'No current service'**
  String get noCurrentService;

  /// No description provided for @noCurrentServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accepted services will appear here as soon as a worker confirms.'**
  String get noCurrentServiceSubtitle;

  /// No description provided for @latestService.
  ///
  /// In en, this message translates to:
  /// **'Latest service'**
  String get latestService;

  /// No description provided for @noServiceHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No service history yet'**
  String get noServiceHistoryYet;

  /// No description provided for @noServiceHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed, cancelled, and disputed services will appear here.'**
  String get noServiceHistorySubtitle;

  /// No description provided for @emergencySafetyCopy.
  ///
  /// In en, this message translates to:
  /// **'For urgent chest pain, severe bleeding, breathing difficulty, or unconsciousness, go directly to a hospital or emergency service.'**
  String get emergencySafetyCopy;

  /// No description provided for @servicesDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the service that best matches the patient need.'**
  String get servicesDashboardSubtitle;

  /// No description provided for @tellWorkersNeed.
  ///
  /// In en, this message translates to:
  /// **'Tell workers what you need'**
  String get tellWorkersNeed;

  /// No description provided for @tellWorkersNeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear details help the right worker decide quickly and arrive prepared.'**
  String get tellWorkersNeedSubtitle;

  /// No description provided for @patientNeed.
  ///
  /// In en, this message translates to:
  /// **'Patient need'**
  String get patientNeed;

  /// No description provided for @issueDetails.
  ///
  /// In en, this message translates to:
  /// **'Issue details'**
  String get issueDetails;

  /// No description provided for @issueDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the patient need, timing, or special care notes'**
  String get issueDetailsHint;

  /// No description provided for @addOptionalIssuePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add optional issue photo'**
  String get addOptionalIssuePhoto;

  /// No description provided for @issuePhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Issue photo selected'**
  String get issuePhotoSelected;

  /// No description provided for @issuePhotoUseful.
  ///
  /// In en, this message translates to:
  /// **'Useful for wounds, bandages, or reports'**
  String get issuePhotoUseful;

  /// No description provided for @serviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Service location'**
  String get serviceLocation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'House, street, area'**
  String get addressHint;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @approvedWorkersOnly.
  ///
  /// In en, this message translates to:
  /// **'Only approved workers who offer this service will be shown.'**
  String get approvedWorkersOnly;

  /// No description provided for @findingWorkers.
  ///
  /// In en, this message translates to:
  /// **'Finding workers...'**
  String get findingWorkers;

  /// No description provided for @findWorkers.
  ///
  /// In en, this message translates to:
  /// **'Find workers'**
  String get findWorkers;

  /// No description provided for @availableWorkers.
  ///
  /// In en, this message translates to:
  /// **'Available workers'**
  String get availableWorkers;

  /// No description provided for @verifiedMatch.
  ///
  /// In en, this message translates to:
  /// **'verified match'**
  String get verifiedMatch;

  /// No description provided for @verifiedMatches.
  ///
  /// In en, this message translates to:
  /// **'verified matches'**
  String get verifiedMatches;

  /// No description provided for @payWorkerDirectly.
  ///
  /// In en, this message translates to:
  /// **'Pay worker directly'**
  String get payWorkerDirectly;

  /// No description provided for @approvedByMediConnect.
  ///
  /// In en, this message translates to:
  /// **'Approved by MediConnect'**
  String get approvedByMediConnect;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @etaShort.
  ///
  /// In en, this message translates to:
  /// **'ETA 25-40 min'**
  String get etaShort;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @sendRequestToWorker.
  ///
  /// In en, this message translates to:
  /// **'Send request to worker'**
  String get sendRequestToWorker;

  /// No description provided for @requestAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Request already sent'**
  String get requestAlreadySent;

  /// No description provided for @requestSentSnack.
  ///
  /// In en, this message translates to:
  /// **'Request sent: {offerId}'**
  String requestSentSnack(Object offerId);

  /// No description provided for @requestSentToWorker.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {workerName}'**
  String requestSentToWorker(Object workerName);

  /// No description provided for @requestSentDescription.
  ///
  /// In en, this message translates to:
  /// **'You can track the service once the worker accepts it. Use chat and call from active orders after acceptance.'**
  String get requestSentDescription;

  /// No description provided for @openActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Open active orders'**
  String get openActiveOrders;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get backHome;

  /// No description provided for @noWorkersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No workers available'**
  String get noWorkersAvailable;

  /// No description provided for @noWorkersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try again later or update the service location.'**
  String get noWorkersSubtitle;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get incomingRequests;

  /// No description provided for @orderAcceptedSnack.
  ///
  /// In en, this message translates to:
  /// **'Order accepted: {orderId}'**
  String orderAcceptedSnack(Object orderId);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @noIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get noIncomingRequests;

  /// No description provided for @noIncomingRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New patient requests will appear here while you are available.'**
  String get noIncomingRequestsSubtitle;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// No description provided for @requestWalletTopUpButton.
  ///
  /// In en, this message translates to:
  /// **'Request JazzCash/EasyPaisa top-up'**
  String get requestWalletTopUpButton;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @noWalletTransactions.
  ///
  /// In en, this message translates to:
  /// **'No wallet transactions yet.'**
  String get noWalletTransactions;

  /// No description provided for @requestWalletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Request wallet top-up'**
  String get requestWalletTopUp;

  /// No description provided for @amountPkr.
  ///
  /// In en, this message translates to:
  /// **'Amount PKR'**
  String get amountPkr;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @transactionReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference'**
  String get transactionReference;

  /// No description provided for @enterTransactionReference.
  ///
  /// In en, this message translates to:
  /// **'Enter the transaction reference'**
  String get enterTransactionReference;

  /// No description provided for @attachScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get attachScreenshot;

  /// No description provided for @screenshotAttached.
  ///
  /// In en, this message translates to:
  /// **'Screenshot attached'**
  String get screenshotAttached;

  /// No description provided for @optionalRecommended.
  ///
  /// In en, this message translates to:
  /// **'Optional but recommended'**
  String get optionalRecommended;

  /// No description provided for @submitTopUpRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit top-up request'**
  String get submitTopUpRequest;

  /// No description provided for @topUpSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Top-up request submitted'**
  String get topUpSubmitted;

  /// No description provided for @issueReported.
  ///
  /// In en, this message translates to:
  /// **'Issue reported'**
  String get issueReported;

  /// No description provided for @cancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel order?'**
  String get cancelOrderQuestion;

  /// No description provided for @cancelOrderWarning.
  ///
  /// In en, this message translates to:
  /// **'Only cancel if the service is no longer needed or the worker cannot continue.'**
  String get cancelOrderWarning;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String patientLabel(Object name);

  /// No description provided for @workerLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker: {name}'**
  String workerLabel(Object name);

  /// No description provided for @activeOrderEmergencyCopy.
  ///
  /// In en, this message translates to:
  /// **'For emergencies, contact local emergency services or go to a hospital. Use report issue for service problems with {name}.'**
  String activeOrderEmergencyCopy(Object name);

  /// No description provided for @checkingWorkerLocation.
  ///
  /// In en, this message translates to:
  /// **'Checking latest worker location...'**
  String get checkingWorkerLocation;

  /// No description provided for @locationUpdatesPending.
  ///
  /// In en, this message translates to:
  /// **'Location updates will appear here after the worker shares GPS.'**
  String get locationUpdatesPending;

  /// No description provided for @latestLocation.
  ///
  /// In en, this message translates to:
  /// **'Latest location: {latitude}, {longitude} at {time}'**
  String latestLocation(Object latitude, Object longitude, Object time);

  /// No description provided for @updatedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAtTime(Object time);

  /// No description provided for @onWay.
  ///
  /// In en, this message translates to:
  /// **'On way'**
  String get onWay;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueTitle;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @serviceHistory.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get serviceHistory;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave review'**
  String get leaveReview;

  /// No description provided for @reviewNotes.
  ///
  /// In en, this message translates to:
  /// **'Review notes'**
  String get reviewNotes;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @serviceNotes.
  ///
  /// In en, this message translates to:
  /// **'Service notes'**
  String get serviceNotes;

  /// No description provided for @workerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Worker dashboard'**
  String get workerDashboard;

  /// No description provided for @locationShared.
  ///
  /// In en, this message translates to:
  /// **'Location shared'**
  String get locationShared;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete order'**
  String get completeOrder;

  /// No description provided for @finalChargePkr.
  ///
  /// In en, this message translates to:
  /// **'Final charge in PKR'**
  String get finalChargePkr;

  /// No description provided for @completionServiceNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional care notes for patient history'**
  String get completionServiceNotesHint;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @verificationStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Verification {status}'**
  String verificationStatusValue(Object status);

  /// No description provided for @workerApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Only approved workers can accept service requests.'**
  String get workerApprovalRequired;

  /// No description provided for @availableForRequests.
  ///
  /// In en, this message translates to:
  /// **'Available for requests'**
  String get availableForRequests;

  /// No description provided for @availableForRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on when you are ready to accept nearby services.'**
  String get availableForRequestsSubtitle;

  /// No description provided for @statWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get statWallet;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @statEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get statEarnings;

  /// No description provided for @statRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get statRequests;

  /// No description provided for @statTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get statTotalOrders;

  /// No description provided for @statRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// No description provided for @viewIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'View incoming requests'**
  String get viewIncomingRequests;

  /// No description provided for @viewRequestCount.
  ///
  /// In en, this message translates to:
  /// **'View {count} request(s)'**
  String viewRequestCount(Object count);

  /// No description provided for @openWallet.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get openWallet;

  /// No description provided for @viewOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'View order history'**
  String get viewOrderHistory;

  /// No description provided for @recentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get recentReviews;

  /// No description provided for @noWorkerReviews.
  ///
  /// In en, this message translates to:
  /// **'Patient reviews will appear here after completed orders.'**
  String get noWorkerReviews;

  /// No description provided for @noActiveOrdersNow.
  ///
  /// In en, this message translates to:
  /// **'No active orders right now.'**
  String get noActiveOrdersNow;

  /// No description provided for @markOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Mark on the way'**
  String get markOnTheWay;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start service'**
  String get startService;

  /// No description provided for @completeService.
  ///
  /// In en, this message translates to:
  /// **'Complete service'**
  String get completeService;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @orderChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This order chat is not available.'**
  String get orderChatUnavailable;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @orderChat.
  ///
  /// In en, this message translates to:
  /// **'Order chat'**
  String get orderChat;

  /// No description provided for @imageAttachmentWithName.
  ///
  /// In en, this message translates to:
  /// **'Image attachment: {name}'**
  String imageAttachmentWithName(Object name);

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'uploaded'**
  String get uploaded;

  /// No description provided for @imageCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Image could not be loaded.'**
  String get imageCouldNotBeLoaded;

  /// No description provided for @imageAttachment.
  ///
  /// In en, this message translates to:
  /// **'Image attachment'**
  String get imageAttachment;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @chatGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use chat for service details, photos, and arrival coordination.'**
  String get chatGuidance;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use MediConnect?'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the account type that matches what you need today.'**
  String get roleSelectionSubtitle;

  /// No description provided for @patientRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientRoleTitle;

  /// No description provided for @patientRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Request home healthcare services and hire verified workers.'**
  String get patientRoleDescription;

  /// No description provided for @workerRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Health worker'**
  String get workerRoleTitle;

  /// No description provided for @workerRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer approved healthcare services after document verification.'**
  String get workerRoleDescription;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient details'**
  String get patientDetails;

  /// No description provided for @patientDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the basic details needed to request home healthcare services.'**
  String get patientDetailsSubtitle;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Karachi, Lahore, Islamabad'**
  String get cityHint;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get emergencyContactPhone;

  /// No description provided for @medicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Medical notes'**
  String get medicalNotes;

  /// No description provided for @medicalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Allergies, existing illness, or important details'**
  String get medicalNotesHint;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @allowLocationAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow location and continue'**
  String get allowLocationAndContinue;

  /// No description provided for @workerVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Health worker verification'**
  String get workerVerificationTitle;

  /// No description provided for @workerVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your qualification, services, and documents. Admin review usually takes 12-24 hours.'**
  String get workerVerificationSubtitle;

  /// No description provided for @workerType.
  ///
  /// In en, this message translates to:
  /// **'Worker type'**
  String get workerType;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @nurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get nurse;

  /// No description provided for @maleNurse.
  ///
  /// In en, this message translates to:
  /// **'Male nurse'**
  String get maleNurse;

  /// No description provided for @otTechnician.
  ///
  /// In en, this message translates to:
  /// **'OT technician'**
  String get otTechnician;

  /// No description provided for @dispenser.
  ///
  /// In en, this message translates to:
  /// **'Dispenser'**
  String get dispenser;

  /// No description provided for @labCollector.
  ///
  /// In en, this message translates to:
  /// **'Lab collector'**
  String get labCollector;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualification;

  /// No description provided for @experienceYears.
  ///
  /// In en, this message translates to:
  /// **'Experience years'**
  String get experienceYears;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get serviceArea;

  /// No description provided for @primaryService.
  ///
  /// In en, this message translates to:
  /// **'Primary service'**
  String get primaryService;

  /// No description provided for @basePricePkr.
  ///
  /// In en, this message translates to:
  /// **'Base price PKR'**
  String get basePricePkr;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain your healthcare experience'**
  String get bioHint;

  /// No description provided for @cnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get cnic;

  /// No description provided for @cnicUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload front/back image or PDF'**
  String get cnicUploadSubtitle;

  /// No description provided for @medicalLicenseOrCertificate.
  ///
  /// In en, this message translates to:
  /// **'Medical license or certificate'**
  String get medicalLicenseOrCertificate;

  /// No description provided for @certificateUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload proof of qualification'**
  String get certificateUploadSubtitle;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @profilePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional image for your worker profile'**
  String get profilePhotoSubtitle;

  /// No description provided for @missingWorkerDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please select CNIC and qualification documents.'**
  String get missingWorkerDocuments;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get submitForVerification;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get verificationRejected;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get verificationPending;

  /// No description provided for @verificationRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review the admin note and resubmit corrected details.'**
  String get verificationRejectedSubtitle;

  /// No description provided for @verificationPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your documents have been submitted. The MediConnect team will review them before you can accept work.'**
  String get verificationPendingSubtitle;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note'**
  String get adminNote;

  /// No description provided for @expectedReviewTime.
  ///
  /// In en, this message translates to:
  /// **'Expected review time'**
  String get expectedReviewTime;

  /// No description provided for @workerCorrectionFallback.
  ///
  /// In en, this message translates to:
  /// **'Documents or profile details need correction.'**
  String get workerCorrectionFallback;

  /// No description provided for @workerReviewTimeCopy.
  ///
  /// In en, this message translates to:
  /// **'Most health worker profiles are reviewed within 12-24 hours.'**
  String get workerReviewTimeCopy;

  /// No description provided for @resubmitDetails.
  ///
  /// In en, this message translates to:
  /// **'Resubmit details'**
  String get resubmitDetails;

  /// No description provided for @reviewSubmittedDetails.
  ///
  /// In en, this message translates to:
  /// **'Review submitted details'**
  String get reviewSubmittedDetails;

  /// No description provided for @pakistanMvp.
  ///
  /// In en, this message translates to:
  /// **'PAKISTAN MVP'**
  String get pakistanMvp;

  /// No description provided for @landingDescription.
  ///
  /// In en, this message translates to:
  /// **'Request verified health workers for basic home services like bandage care, injections, drips, blood samples, and checkups.'**
  String get landingDescription;

  /// No description provided for @verifiedWorkers.
  ///
  /// In en, this message translates to:
  /// **'Verified workers'**
  String get verifiedWorkers;

  /// No description provided for @cashServicePayment.
  ///
  /// In en, this message translates to:
  /// **'Cash service payment'**
  String get cashServicePayment;

  /// No description provided for @landingEmergencyCopy.
  ///
  /// In en, this message translates to:
  /// **'MediConnect is for basic doorstep healthcare support. For emergencies, go to a hospital or local emergency service.'**
  String get landingEmergencyCopy;

  /// No description provided for @chooseHowToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose how to continue'**
  String get chooseHowToContinue;

  /// No description provided for @patientEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and request a nearby verified worker.'**
  String get patientEntrySubtitle;

  /// No description provided for @workerEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit documents and offer services after approval.'**
  String get workerEntrySubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Verification, order, and wallet updates appear here.'**
  String get notificationsEmpty;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
