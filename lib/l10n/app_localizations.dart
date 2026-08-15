import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @tabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get tabSaved;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @offlineShowingCached.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing your last saved matches'**
  String get offlineShowingCached;

  /// No description provided for @completeProfileCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileCtaTitle;

  /// No description provided for @completeProfileCtaMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get personalized recommendations'**
  String get completeProfileCtaMessage;

  /// No description provided for @completeProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfileButton;

  /// No description provided for @couldNotLoadRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load recommendations'**
  String get couldNotLoadRecommendations;

  /// No description provided for @upgradeToSeeAllRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to see all recommendations'**
  String get upgradeToSeeAllRecommendations;

  /// No description provided for @filterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country / Region'**
  String get filterCountry;

  /// No description provided for @filterDegreeLevel.
  ///
  /// In en, this message translates to:
  /// **'Degree level'**
  String get filterDegreeLevel;

  /// No description provided for @filterFeeRange.
  ///
  /// In en, this message translates to:
  /// **'Annual fee range'**
  String get filterFeeRange;

  /// No description provided for @filterFieldOfStudy.
  ///
  /// In en, this message translates to:
  /// **'Field of study'**
  String get filterFieldOfStudy;

  /// No description provided for @filterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language of instruction'**
  String get filterLanguage;

  /// No description provided for @fieldsShort.
  ///
  /// In en, this message translates to:
  /// **'fields'**
  String get fieldsShort;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compareSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String compareSelectedCount(int count);

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @upgradeToSeeAllMatches.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to see all matches'**
  String get upgradeToSeeAllMatches;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved universities yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any university to build your shortlist.'**
  String get savedEmptyMessage;

  /// No description provided for @exploreUniversities.
  ///
  /// In en, this message translates to:
  /// **'Explore universities'**
  String get exploreUniversities;

  /// No description provided for @folderEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items in this folder'**
  String get folderEmptyTitle;

  /// No description provided for @aboutThisUniversity.
  ///
  /// In en, this message translates to:
  /// **'About this university'**
  String get aboutThisUniversity;

  /// No description provided for @programsTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @mapNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview not available'**
  String get mapNotAvailable;

  /// No description provided for @studentsAlsoViewed.
  ///
  /// In en, this message translates to:
  /// **'Students like you also viewed'**
  String get studentsAlsoViewed;

  /// No description provided for @lockedAlsoViewedMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro or Premium to unlock peer insights.'**
  String get lockedAlsoViewedMessage;

  /// No description provided for @bookCounselorSession.
  ///
  /// In en, this message translates to:
  /// **'Book a counselor session about this university'**
  String get bookCounselorSession;

  /// No description provided for @counselorBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Counselor booking'**
  String get counselorBookingTitle;

  /// No description provided for @counselorBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking is part of a separate module coming soon.'**
  String get counselorBookingMessage;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @compareStubMessage.
  ///
  /// In en, this message translates to:
  /// **'Full side-by-side comparison is coming soon. Here are your selected programs.'**
  String get compareStubMessage;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortFeeAsc.
  ///
  /// In en, this message translates to:
  /// **'Fee: low to high'**
  String get sortFeeAsc;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'University A–Z'**
  String get sortAlphabetical;

  /// No description provided for @couldNotUpdateSaved.
  ///
  /// In en, this message translates to:
  /// **'Could not update saved universities: {error}'**
  String couldNotUpdateSaved(String error);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @recommendedUniversities.
  ///
  /// In en, this message translates to:
  /// **'Recommended Universities'**
  String get recommendedUniversities;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get noRecommendationsTitle;

  /// No description provided for @noRecommendationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Universities matched to your profile will appear here once our discovery catalogue goes live.'**
  String get noRecommendationsMessage;

  /// No description provided for @counsellorSession.
  ///
  /// In en, this message translates to:
  /// **'Counsellor Session'**
  String get counsellorSession;

  /// No description provided for @noSessionsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No sessions scheduled'**
  String get noSessionsScheduled;

  /// No description provided for @noUpcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'No upcoming sessions'**
  String get noUpcomingSessions;

  /// No description provided for @sessionsCounsellorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sessions you book with students will show up here.'**
  String get sessionsCounsellorEmpty;

  /// No description provided for @sessionsStudentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Book a session with a counsellor and it will be surfaced here so you never miss it.'**
  String get sessionsStudentEmpty;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'booked'**
  String get booked;

  /// No description provided for @suggestedClassrooms.
  ///
  /// In en, this message translates to:
  /// **'Suggested Classrooms'**
  String get suggestedClassrooms;

  /// No description provided for @noClassroomsYet.
  ///
  /// In en, this message translates to:
  /// **'No classrooms yet'**
  String get noClassroomsYet;

  /// No description provided for @noClassroomsMessage.
  ///
  /// In en, this message translates to:
  /// **'Classrooms matching your interests will be suggested here.'**
  String get noClassroomsMessage;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @nothingNewYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing new yet'**
  String get nothingNewYet;

  /// No description provided for @activityMessage.
  ///
  /// In en, this message translates to:
  /// **'Activity from people you follow — new posts, follows and session updates — will appear here.'**
  String get activityMessage;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search people, universities, classrooms...'**
  String get searchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @suggestedSearches.
  ///
  /// In en, this message translates to:
  /// **'Suggested searches'**
  String get suggestedSearches;

  /// No description provided for @trendingSearches.
  ///
  /// In en, this message translates to:
  /// **'Trending searches'**
  String get trendingSearches;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @tabPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get tabPeople;

  /// No description provided for @tabUniversities.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get tabUniversities;

  /// No description provided for @tabClassrooms.
  ///
  /// In en, this message translates to:
  /// **'Classrooms'**
  String get tabClassrooms;

  /// No description provided for @tabPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get tabPosts;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get filterStudents;

  /// No description provided for @filterCounsellors.
  ///
  /// In en, this message translates to:
  /// **'Counsellors'**
  String get filterCounsellors;

  /// No description provided for @noUniversitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No universities found'**
  String get noUniversitiesFound;

  /// No description provided for @noClassroomsFound.
  ///
  /// In en, this message translates to:
  /// **'No classrooms found'**
  String get noClassroomsFound;

  /// No description provided for @noPeopleFound.
  ///
  /// In en, this message translates to:
  /// **'No people found for \"{query}\"'**
  String noPeopleFound(String query);

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found for \"{query}\"'**
  String noPostsFound(String query);

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword or check your spelling.'**
  String get tryDifferentKeyword;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleCounsellor.
  ///
  /// In en, this message translates to:
  /// **'Counsellor'**
  String get roleCounsellor;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This user may have deleted their account.'**
  String get profileNotFoundMessage;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile'**
  String get couldNotLoadProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @profileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied to clipboard'**
  String get profileLinkCopied;

  /// No description provided for @fullProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Full profile details'**
  String get fullProfileDetails;

  /// No description provided for @sectionAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get sectionAcademic;

  /// No description provided for @labelEducationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education level'**
  String get labelEducationLevel;

  /// No description provided for @labelDesiredDegree.
  ///
  /// In en, this message translates to:
  /// **'Desired degree'**
  String get labelDesiredDegree;

  /// No description provided for @labelFieldsOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Fields of interest'**
  String get labelFieldsOfInterest;

  /// No description provided for @labelPlannedStart.
  ///
  /// In en, this message translates to:
  /// **'Planned start'**
  String get labelPlannedStart;

  /// No description provided for @sectionLocationLogistics.
  ///
  /// In en, this message translates to:
  /// **'Location & Logistics'**
  String get sectionLocationLogistics;

  /// No description provided for @labelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get labelHome;

  /// No description provided for @labelStudyDestinations.
  ///
  /// In en, this message translates to:
  /// **'Study destinations'**
  String get labelStudyDestinations;

  /// No description provided for @labelLanguageOfInstruction.
  ///
  /// In en, this message translates to:
  /// **'Language of instruction'**
  String get labelLanguageOfInstruction;

  /// No description provided for @sectionFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get sectionFinancial;

  /// No description provided for @labelAnnualBudget.
  ///
  /// In en, this message translates to:
  /// **'Annual budget'**
  String get labelAnnualBudget;

  /// No description provided for @labelHouseholdIncome.
  ///
  /// In en, this message translates to:
  /// **'Household income'**
  String get labelHouseholdIncome;

  /// No description provided for @labelScholarships.
  ///
  /// In en, this message translates to:
  /// **'Scholarships'**
  String get labelScholarships;

  /// No description provided for @seekingScholarship.
  ///
  /// In en, this message translates to:
  /// **'Seeking scholarship info'**
  String get seekingScholarship;

  /// No description provided for @notSeekingScholarship.
  ///
  /// In en, this message translates to:
  /// **'Not currently seeking'**
  String get notSeekingScholarship;

  /// No description provided for @sectionAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get sectionAssessment;

  /// No description provided for @labelCareerGoal.
  ///
  /// In en, this message translates to:
  /// **'Career goal'**
  String get labelCareerGoal;

  /// No description provided for @labelStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get labelStrengths;

  /// No description provided for @labelInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get labelInterests;

  /// No description provided for @labelGpa.
  ///
  /// In en, this message translates to:
  /// **'GPA'**
  String get labelGpa;

  /// No description provided for @labelTestScores.
  ///
  /// In en, this message translates to:
  /// **'Test scores'**
  String get labelTestScores;

  /// No description provided for @addBioPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a short bio so students and counsellors can learn more about you.'**
  String get addBioPrompt;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get photoUpdated;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo: {error}'**
  String photoUploadFailed(String error);

  /// No description provided for @photoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access was denied. Allow it in your device settings and try again.'**
  String get photoPermissionDenied;

  /// No description provided for @statFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get statFollowers;

  /// No description provided for @statFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get statFollowing;

  /// No description provided for @statPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get statPosts;

  /// No description provided for @roleVerifiedCounsellor.
  ///
  /// In en, this message translates to:
  /// **'Verified Counsellor'**
  String get roleVerifiedCounsellor;

  /// No description provided for @academicProfile.
  ///
  /// In en, this message translates to:
  /// **'Academic Profile'**
  String get academicProfile;

  /// No description provided for @fullDetails.
  ///
  /// In en, this message translates to:
  /// **'Full details'**
  String get fullDetails;

  /// No description provided for @labelEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get labelEducation;

  /// No description provided for @labelDegreeGoal.
  ///
  /// In en, this message translates to:
  /// **'Degree goal'**
  String get labelDegreeGoal;

  /// No description provided for @labelFieldOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Field of interest'**
  String get labelFieldOfInterest;

  /// No description provided for @savedUniversityOne.
  ///
  /// In en, this message translates to:
  /// **'{count} saved university'**
  String savedUniversityOne(int count);

  /// No description provided for @savedUniversityMany.
  ///
  /// In en, this message translates to:
  /// **'{count} saved universities'**
  String savedUniversityMany(int count);

  /// No description provided for @saveUniversitiesCta.
  ///
  /// In en, this message translates to:
  /// **'Save universities to build your shortlist'**
  String get saveUniversitiesCta;

  /// No description provided for @postsTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get postsTitle;

  /// No description provided for @shareYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Share your journey'**
  String get shareYourJourney;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @postsJourneyMessage.
  ///
  /// In en, this message translates to:
  /// **'Posts about your study-abroad journey will appear here.'**
  String get postsJourneyMessage;

  /// No description provided for @studentNoPostsMessage.
  ///
  /// In en, this message translates to:
  /// **'This student has not posted anything yet.'**
  String get studentNoPostsMessage;

  /// No description provided for @writeFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Write your first post'**
  String get writeFirstPost;

  /// No description provided for @postOptions.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get postOptions;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPost;

  /// No description provided for @whatOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What is on your mind?'**
  String get whatOnYourMind;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostTitle;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @couldNotUpdateLike.
  ///
  /// In en, this message translates to:
  /// **'Could not update like: {error}'**
  String couldNotUpdateLike(String error);

  /// No description provided for @couldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes: {error}'**
  String couldNotSaveChanges(String error);

  /// No description provided for @couldNotDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Could not delete post: {error}'**
  String couldNotDeletePost(String error);

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get noFollowersYet;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get notFollowingAnyone;

  /// No description provided for @followersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When other students and counsellors follow you, they will show up here.'**
  String get followersEmptyMessage;

  /// No description provided for @followingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Follow students and counsellors to see their activity in your feed.'**
  String get followingEmptyMessage;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @couldNotSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile: {error}'**
  String couldNotSaveProfile(String error);

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @bioTooLong.
  ///
  /// In en, this message translates to:
  /// **'Bio must be 250 characters or fewer'**
  String get bioTooLong;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get labelFullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ada Lovelace'**
  String get fullNameHint;

  /// No description provided for @labelCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get labelCountry;

  /// No description provided for @tapToSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Tap to select your country'**
  String get tapToSelectCountry;

  /// No description provided for @labelCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get labelCity;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lagos'**
  String get cityHint;

  /// No description provided for @labelBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get labelBio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aspiring software engineer passionate about renewable energy'**
  String get bioHint;

  /// No description provided for @academicInformation.
  ///
  /// In en, this message translates to:
  /// **'Academic Information'**
  String get academicInformation;

  /// No description provided for @yourCustomField.
  ///
  /// In en, this message translates to:
  /// **'Your custom field'**
  String get yourCustomField;

  /// No description provided for @customFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your field of interest...'**
  String get customFieldHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @noProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No profile found'**
  String get noProfileFound;

  /// No description provided for @completeOnboardingFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete the onboarding first so you have a profile to edit.'**
  String get completeOnboardingFirst;

  /// No description provided for @completeMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete my profile'**
  String get completeMyProfile;

  /// No description provided for @couldNotLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile'**
  String get couldNotLoadYourProfile;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @passwordResetHint.
  ///
  /// In en, this message translates to:
  /// **'We will email you a reset link'**
  String get passwordResetHint;

  /// No description provided for @linkedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Linked Google account'**
  String get linkedGoogle;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notLinked;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @settingNewFollowers.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get settingNewFollowers;

  /// No description provided for @settingMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settingMessages;

  /// No description provided for @settingClassroomActivity.
  ///
  /// In en, this message translates to:
  /// **'Classroom activity'**
  String get settingClassroomActivity;

  /// No description provided for @settingBookingReminders.
  ///
  /// In en, this message translates to:
  /// **'Booking reminders'**
  String get settingBookingReminders;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language preference'**
  String get languagePreference;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySection;

  /// No description provided for @whoCanMessageYou.
  ///
  /// In en, this message translates to:
  /// **'Who can message you'**
  String get whoCanMessageYou;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @followersOnly.
  ///
  /// In en, this message translates to:
  /// **'Followers only'**
  String get followersOnly;

  /// No description provided for @showSavedUniversities.
  ///
  /// In en, this message translates to:
  /// **'Show my saved universities'**
  String get showSavedUniversities;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account actions'**
  String get accountActions;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutHint.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get logoutHint;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your profile and data'**
  String get deleteAccountHint;

  /// No description provided for @dataSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Orientaa keeps your data safe. Deleting your account is permanent.'**
  String get dataSafetyNote;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password?'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'We will send a password reset link to {email}.'**
  String resetPasswordMessage(String email);

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}'**
  String passwordResetSent(String email);

  /// No description provided for @couldNotSendReset.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset link: {error}'**
  String couldNotSendReset(String error);

  /// No description provided for @noEmailOnAccount.
  ///
  /// In en, this message translates to:
  /// **'No email address on this account'**
  String get noEmailOnAccount;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your profile.'**
  String get logoutConfirmMessage;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your profile, posts and settings. Type your email to confirm:'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @emailDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Email does not match'**
  String get emailDoesNotMatch;

  /// No description provided for @requiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then try deleting your account.'**
  String get requiresRecentLogin;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {error}'**
  String couldNotDeleteAccount(String error);

  /// No description provided for @couldNotSaveSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not save setting: {error}'**
  String couldNotSaveSetting(String error);

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themePreference.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themePreference;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @startConversationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with a student or counsellor.'**
  String get startConversationPrompt;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @messagesPrivacyBlocked.
  ///
  /// In en, this message translates to:
  /// **'This user only accepts messages from people they follow.'**
  String get messagesPrivacyBlocked;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search students and counsellors...'**
  String get searchUsersHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @searchByNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by name to start a conversation'**
  String get searchByNamePrompt;

  /// No description provided for @counsellorSessionChip.
  ///
  /// In en, this message translates to:
  /// **'Counsellor Session'**
  String get counsellorSessionChip;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}!'**
  String sayHello(String name);

  /// No description provided for @conversationStart.
  ///
  /// In en, this message translates to:
  /// **'This is the start of your conversation.'**
  String get conversationStart;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @couldNotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not send message: {error}'**
  String couldNotSendMessage(String error);

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @postHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get postHint;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @publishPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get publishPost;

  /// No description provided for @posting.
  ///
  /// In en, this message translates to:
  /// **'Posting...'**
  String get posting;

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Your post was published.'**
  String get postPublished;

  /// No description provided for @couldNotPublishPost.
  ///
  /// In en, this message translates to:
  /// **'Could not publish your post: {error}'**
  String couldNotPublishPost(String error);

  /// No description provided for @writeSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Write something before posting.'**
  String get writeSomethingFirst;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Orientaa'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your career. Your future.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeChipExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get welcomeChipExplore;

  /// No description provided for @welcomeChipCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get welcomeChipCompare;

  /// No description provided for @welcomeChipGetMatched.
  ///
  /// In en, this message translates to:
  /// **'Get matched'**
  String get welcomeChipGetMatched;

  /// No description provided for @welcomeFindPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your path'**
  String get welcomeFindPathTitle;

  /// No description provided for @welcomeFindPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover universities, courses and scholarships across Africa and the world — tailored to you.'**
  String get welcomeFindPathSubtitle;

  /// No description provided for @welcomeReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to begin?'**
  String get welcomeReadyTitle;

  /// No description provided for @welcomeReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account in minutes and start exploring opportunities built around your goals.'**
  String get welcomeReadySubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'I already have an account — Log in'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, explorer!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions and Orientaa will chart your path to studying anywhere in the world.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingChipTailored.
  ///
  /// In en, this message translates to:
  /// **'Tailored matches'**
  String get onboardingChipTailored;

  /// No description provided for @onboardingChipScholarships.
  ///
  /// In en, this message translates to:
  /// **'Scholarships'**
  String get onboardingChipScholarships;

  /// No description provided for @onboardingChipExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert guidance'**
  String get onboardingChipExpert;

  /// No description provided for @howWillYouUse.
  ///
  /// In en, this message translates to:
  /// **'How will you use Orientaa?'**
  String get howWillYouUse;

  /// No description provided for @pickRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your role to personalize your experience'**
  String get pickRoleSubtitle;

  /// No description provided for @selectRoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a role to continue'**
  String get selectRoleToContinue;

  /// No description provided for @roleStudentDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore universities, courses, scholarships, and manage your academic journey.'**
  String get roleStudentDescription;

  /// No description provided for @roleCounsellorDescription.
  ///
  /// In en, this message translates to:
  /// **'Guide students, manage counselling sessions, and support their educational success.'**
  String get roleCounsellorDescription;

  /// No description provided for @selectRoleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Select {role} role'**
  String selectRoleSemantics(String role);

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue your journey'**
  String get loginSubtitle;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @sendSignInLinkPasswordless.
  ///
  /// In en, this message translates to:
  /// **'Send Sign-In Link (Passwordless)'**
  String get sendSignInLinkPasswordless;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// No description provided for @pleaseEnterEmailToComplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email to complete sign-in.'**
  String get pleaseEnterEmailToComplete;

  /// No description provided for @signedInWithEmailLink.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in with email link.'**
  String get signedInWithEmailLink;

  /// No description provided for @emailLinkSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Email link sign-in failed: {error}'**
  String emailLinkSignInFailed(String error);

  /// No description provided for @confirmYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get confirmYourEmail;

  /// No description provided for @signInLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Sign-in link sent to {email}'**
  String signInLinkSent(String email);

  /// No description provided for @enterValidEmailForLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email to receive a sign-in link'**
  String get enterValidEmailForLink;

  /// No description provided for @failedToSendSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to send sign-in link: {error}'**
  String failedToSendSignInLink(String error);

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified. A new verification email has been sent to {email}. Please check your inbox (and spam folder) and click the verification link.'**
  String emailNotVerified(String email);

  /// No description provided for @googleSignInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in successful'**
  String get googleSignInSuccessful;

  /// No description provided for @verificationResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email re-sent to {email}. Please check your inbox.'**
  String verificationResent(String email);

  /// No description provided for @failedToResendVerification.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend verification: {error}'**
  String failedToResendVerification(String error);

  /// No description provided for @emailExampleHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailExampleHint;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your journey with Orientaa'**
  String get signupSubtitle;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get enterAPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {email}. Please verify your email before logging in.'**
  String verificationEmailSentTo(String email);

  /// No description provided for @resetPasswordHeader.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordHeader;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @tabCounselors.
  ///
  /// In en, this message translates to:
  /// **'Counselors'**
  String get tabCounselors;

  /// No description provided for @counselorDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Counselors'**
  String get counselorDirectoryTitle;

  /// No description provided for @counselorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search counselors by name or specialty…'**
  String get counselorSearchHint;

  /// No description provided for @perSession.
  ///
  /// In en, this message translates to:
  /// **'per session'**
  String get perSession;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @noCounselorsMatch.
  ///
  /// In en, this message translates to:
  /// **'No counselors match these filters — try widening your search.'**
  String get noCounselorsMatch;

  /// No description provided for @counselorSearchNameNote.
  ///
  /// In en, this message translates to:
  /// **'Name search narrows the results already loaded.'**
  String get counselorSearchNameNote;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sortRecommended;

  /// No description provided for @sortPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLowToHigh;

  /// No description provided for @sortRatingHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Rating: high to low'**
  String get sortRatingHighToLow;

  /// No description provided for @filterOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get filterOnlineOnly;

  /// No description provided for @filterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get filterPriceRange;

  /// No description provided for @filterLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguageLabel;

  /// No description provided for @filterSpecialtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get filterSpecialtyLabel;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'Any language'**
  String get allLanguages;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @counselorVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get counselorVerifiedBadge;

  /// No description provided for @credentialsVerified.
  ///
  /// In en, this message translates to:
  /// **'Credentials verified ✓'**
  String get credentialsVerified;

  /// No description provided for @credentialsNote.
  ///
  /// In en, this message translates to:
  /// **'This counselor\'s qualifications were reviewed by our team.'**
  String get credentialsNote;

  /// No description provided for @specialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get specialtiesTitle;

  /// No description provided for @languagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesTitle;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @nextAvailability.
  ///
  /// In en, this message translates to:
  /// **'Next available sessions'**
  String get nextAvailability;

  /// No description provided for @noAvailability.
  ///
  /// In en, this message translates to:
  /// **'No upcoming availability right now'**
  String get noAvailability;

  /// No description provided for @bookSessionCta.
  ///
  /// In en, this message translates to:
  /// **'Book Session — {price} for 60 min'**
  String bookSessionCta(String price);

  /// No description provided for @sessionLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'60 minutes'**
  String get sessionLengthLabel;

  /// No description provided for @sessionFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Session fee'**
  String get sessionFeeLabel;

  /// No description provided for @platformCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform commission (10%)'**
  String get platformCommissionLabel;

  /// No description provided for @commissionNote.
  ///
  /// In en, this message translates to:
  /// **'This commission is deducted from the counselor\'s payout — the price you see is all you pay.'**
  String get commissionNote;

  /// No description provided for @confirmSlot.
  ///
  /// In en, this message translates to:
  /// **'Confirm slot'**
  String get confirmSlot;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get selectTimeSlot;

  /// No description provided for @selectSlotHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an available 60-minute slot'**
  String get selectSlotHint;

  /// No description provided for @noSlotsForDate.
  ///
  /// In en, this message translates to:
  /// **'No available slots on this date — try another day.'**
  String get noSlotsForDate;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get bookingSummary;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing payment…'**
  String get paymentProcessing;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your payment didn\'t go through. Your slot is still reserved — you can retry.'**
  String get paymentFailedMessage;

  /// No description provided for @retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry payment'**
  String get retryPayment;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'A reminder will be sent 15 minutes before your session starts.'**
  String get bookingConfirmedMessage;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @goToMySessions.
  ///
  /// In en, this message translates to:
  /// **'Go to My Sessions'**
  String get goToMySessions;

  /// No description provided for @mySessions.
  ///
  /// In en, this message translates to:
  /// **'My Sessions'**
  String get mySessions;

  /// No description provided for @sessionStartsAt.
  ///
  /// In en, this message translates to:
  /// **'This session starts at {time}'**
  String sessionStartsAt(String time);

  /// No description provided for @sessionHasEnded.
  ///
  /// In en, this message translates to:
  /// **'This session has ended'**
  String get sessionHasEnded;

  /// No description provided for @sessionChatHint.
  ///
  /// In en, this message translates to:
  /// **'Chat with your counselor about this session.'**
  String get sessionChatHint;

  /// No description provided for @joinSessionChat.
  ///
  /// In en, this message translates to:
  /// **'Join session chat'**
  String get joinSessionChat;

  /// No description provided for @checkPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid — check status'**
  String get checkPaymentStatus;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// No description provided for @reportIssueStub.
  ///
  /// In en, this message translates to:
  /// **'Thanks for letting us know — our support team will reach out about this session.'**
  String get reportIssueStub;

  /// No description provided for @sessionUpcomingBadge.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sessionUpcomingBadge;

  /// No description provided for @sessionLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get sessionLiveBadge;

  /// No description provided for @sessionEndedBadge.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get sessionEndedBadge;

  /// No description provided for @sessionCancelled.
  ///
  /// In en, this message translates to:
  /// **'This session was cancelled'**
  String get sessionCancelled;

  /// No description provided for @sessionRefunded.
  ///
  /// In en, this message translates to:
  /// **'This session was refunded'**
  String get sessionRefunded;

  /// No description provided for @didSessionHappen.
  ///
  /// In en, this message translates to:
  /// **'Did this session happen as scheduled?'**
  String get didSessionHappen;

  /// No description provided for @yesItHappened.
  ///
  /// In en, this message translates to:
  /// **'Yes, it happened'**
  String get yesItHappened;

  /// No description provided for @noReportProblem.
  ///
  /// In en, this message translates to:
  /// **'No, something went wrong'**
  String get noReportProblem;

  /// No description provided for @rateYourSession.
  ///
  /// In en, this message translates to:
  /// **'How was your session?'**
  String get rateYourSession;

  /// No description provided for @rateHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get rateHint;

  /// No description provided for @reviewOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Write a review (optional)'**
  String get reviewOptionalHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get thanksForRating;

  /// No description provided for @rateLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get rateLater;

  /// No description provided for @whatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get whatWentWrong;

  /// No description provided for @disputeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the problem — our team will review it.'**
  String get disputeReasonHint;

  /// No description provided for @submitDispute.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitDispute;

  /// No description provided for @disputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — our team will review this shortly.'**
  String get disputeSubmitted;

  /// No description provided for @confirmSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Did the session happen?'**
  String get confirmSessionTitle;

  /// No description provided for @confirmSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm session'**
  String get confirmSessionAction;

  /// No description provided for @sessionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Session confirmed. The counselor\'s payout is being processed.'**
  String get sessionConfirmed;

  /// No description provided for @bookingStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get bookingStatusRequested;

  /// No description provided for @bookingStatusPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get bookingStatusPaymentPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get bookingStatusDisputed;

  /// No description provided for @bookingStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get bookingStatusRefunded;

  /// No description provided for @bookingStatusPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get bookingStatusPaidOut;

  /// No description provided for @emptySessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Browse counselors to book your first one.'**
  String get emptySessions;

  /// No description provided for @emptySessionsCounselor.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Once students book you, they\'ll show up here.'**
  String get emptySessionsCounselor;

  /// No description provided for @browseCounselors.
  ///
  /// In en, this message translates to:
  /// **'Browse counselors'**
  String get browseCounselors;

  /// No description provided for @becomeCounselor.
  ///
  /// In en, this message translates to:
  /// **'Become a counselor'**
  String get becomeCounselor;

  /// No description provided for @becomeCounselorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer 1:1 sessions and get paid for your expertise.'**
  String get becomeCounselorSubtitle;

  /// No description provided for @setUpCounselorProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your counselor profile'**
  String get setUpCounselorProfile;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @counselorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Counselor workspace'**
  String get counselorDashboard;

  /// No description provided for @dashboardCounselorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Counselors'**
  String get dashboardCounselorsTitle;

  /// No description provided for @dashboardCounselorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book 1:1 sessions with verified experts'**
  String get dashboardCounselorsSubtitle;

  /// No description provided for @dashboardNextSession.
  ///
  /// In en, this message translates to:
  /// **'Your next session'**
  String get dashboardNextSession;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @totalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get totalToPay;

  /// No description provided for @currencyNote.
  ///
  /// In en, this message translates to:
  /// **'Your bank or mobile-money provider may apply a conversion rate — the amount above is what you pay.'**
  String get currencyNote;

  /// No description provided for @chargedAmount.
  ///
  /// In en, this message translates to:
  /// **'Charged amount'**
  String get chargedAmount;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @withCounselor.
  ///
  /// In en, this message translates to:
  /// **'Session with {name}'**
  String withCounselor(String name);

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send message'**
  String get messageSendFailed;

  /// No description provided for @viewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get viewBooking;

  /// No description provided for @counselorSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Counselor profile'**
  String get counselorSetupTitle;

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Session price ({currency})'**
  String hourlyRateLabel(String currency);

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly availability'**
  String get availabilityLabel;

  /// No description provided for @addAvailabilitySlot.
  ///
  /// In en, this message translates to:
  /// **'Add availability'**
  String get addAvailabilitySlot;

  /// No description provided for @removeAvailabilitySlot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAvailabilitySlot;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTimeLabel;

  /// No description provided for @specialtiesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Scholarships, Study abroad'**
  String get specialtiesHint;

  /// No description provided for @languagesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English, French'**
  String get languagesHint;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @uploadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Upload credentials (PDF or image)'**
  String get uploadCredentials;

  /// No description provided for @credentialsUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Diploma, certificate or license — shown only to our review team.'**
  String get credentialsUploadHint;

  /// No description provided for @credentialsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Credentials submitted — we\'ll review them soon.'**
  String get credentialsSubmitted;

  /// No description provided for @verificationPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Your profile is under review. Students can\'t book you yet.'**
  String get verificationPendingNote;

  /// No description provided for @verificationRejectedNote.
  ///
  /// In en, this message translates to:
  /// **'Your verification was rejected. Please re-upload valid credentials.'**
  String get verificationRejectedNote;

  /// No description provided for @reuploadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Re-upload credentials'**
  String get reuploadCredentials;

  /// No description provided for @getAvailableSlotsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load available slots. Please try again.'**
  String get getAvailableSlotsError;

  /// No description provided for @bookingCreationError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the booking. Please try again.'**
  String get bookingCreationError;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the payment. Please try again.'**
  String get paymentError;

  /// No description provided for @adminDisputesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute review'**
  String get adminDisputesTitle;

  /// No description provided for @adminDisputesOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminDisputesOpen;

  /// No description provided for @adminDisputesResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminDisputesResolved;

  /// No description provided for @adminDisputesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No disputes to review right now'**
  String get adminDisputesEmpty;

  /// No description provided for @adminOnlyError.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminOnlyError;

  /// No description provided for @adminDisputesEntry.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get adminDisputesEntry;

  /// No description provided for @disputeReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported reason'**
  String get disputeReasonLabel;

  /// No description provided for @disputeScheduledLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get disputeScheduledLabel;

  /// No description provided for @disputeResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve dispute'**
  String get disputeResolveTitle;

  /// No description provided for @resolvePayCounselor.
  ///
  /// In en, this message translates to:
  /// **'Pay the counselor'**
  String get resolvePayCounselor;

  /// No description provided for @resolveRefundStudent.
  ///
  /// In en, this message translates to:
  /// **'Refund the student'**
  String get resolveRefundStudent;

  /// No description provided for @resolvePayBody.
  ///
  /// In en, this message translates to:
  /// **'Reject the dispute and pay the counselor their full payout?'**
  String get resolvePayBody;

  /// No description provided for @resolveRefundBody.
  ///
  /// In en, this message translates to:
  /// **'Uphold the dispute and refund the student in full?'**
  String get resolveRefundBody;

  /// No description provided for @resolveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolved'**
  String get resolveSuccess;

  /// No description provided for @resolveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resolve the dispute. Please try again.'**
  String get resolveError;

  /// No description provided for @counselorOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a counselor'**
  String get counselorOnboardingTitle;

  /// No description provided for @onboardingStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get onboardingStepIdentity;

  /// No description provided for @onboardingStepPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get onboardingStepPractice;

  /// No description provided for @onboardingStepPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get onboardingStepPricing;

  /// No description provided for @onboardingStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get onboardingStepVerify;

  /// No description provided for @onboardingIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell students who you are'**
  String get onboardingIdentitySubtitle;

  /// No description provided for @onboardingPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your specialties, languages and bio'**
  String get onboardingPracticeSubtitle;

  /// No description provided for @onboardingPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your session rate and weekly availability'**
  String get onboardingPricingSubtitle;

  /// No description provided for @onboardingVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a credential and add your payout account'**
  String get onboardingVerifySubtitle;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingFinish;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile is under review. We\'ll notify you once you\'re verified and bookable.'**
  String get onboardingDoneBody;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'View my profile'**
  String get goToProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
