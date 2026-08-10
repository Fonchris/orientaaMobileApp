// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabProfile => 'Profile';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get recommendedUniversities => 'Recommended Universities';

  @override
  String get seeAll => 'See all';

  @override
  String get noRecommendationsTitle => 'No recommendations yet';

  @override
  String get noRecommendationsMessage =>
      'Universities matched to your profile will appear here once our discovery catalogue goes live.';

  @override
  String get counsellorSession => 'Counsellor Session';

  @override
  String get noSessionsScheduled => 'No sessions scheduled';

  @override
  String get noUpcomingSessions => 'No upcoming sessions';

  @override
  String get sessionsCounsellorEmpty =>
      'Sessions you book with students will show up here.';

  @override
  String get sessionsStudentEmpty =>
      'Book a session with a counsellor and it will be surfaced here so you never miss it.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get booked => 'booked';

  @override
  String get suggestedClassrooms => 'Suggested Classrooms';

  @override
  String get noClassroomsYet => 'No classrooms yet';

  @override
  String get noClassroomsMessage =>
      'Classrooms matching your interests will be suggested here.';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get nothingNewYet => 'Nothing new yet';

  @override
  String get activityMessage =>
      'Activity from people you follow — new posts, follows and session updates — will appear here.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search people, universities, classrooms...';

  @override
  String get clear => 'Clear';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get suggestedSearches => 'Suggested searches';

  @override
  String get trendingSearches => 'Trending searches';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get tabPeople => 'People';

  @override
  String get tabUniversities => 'Universities';

  @override
  String get tabClassrooms => 'Classrooms';

  @override
  String get tabPosts => 'Posts';

  @override
  String get filterAll => 'All';

  @override
  String get filterStudents => 'Students';

  @override
  String get filterCounsellors => 'Counsellors';

  @override
  String get noUniversitiesFound => 'No universities found';

  @override
  String get noClassroomsFound => 'No classrooms found';

  @override
  String noPeopleFound(String query) {
    return 'No people found for \"$query\"';
  }

  @override
  String noPostsFound(String query) {
    return 'No posts found for \"$query\"';
  }

  @override
  String get tryDifferentKeyword =>
      'Try a different keyword or check your spelling.';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleCounsellor => 'Counsellor';

  @override
  String get myProfile => 'My Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileNotFoundMessage =>
      'This user may have deleted their account.';

  @override
  String get couldNotLoadProfile => 'Could not load this profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get share => 'Share';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get message => 'Message';

  @override
  String get profileLinkCopied => 'Profile link copied to clipboard';

  @override
  String get fullProfileDetails => 'Full profile details';

  @override
  String get sectionAcademic => 'Academic';

  @override
  String get labelEducationLevel => 'Education level';

  @override
  String get labelDesiredDegree => 'Desired degree';

  @override
  String get labelFieldsOfInterest => 'Fields of interest';

  @override
  String get labelPlannedStart => 'Planned start';

  @override
  String get sectionLocationLogistics => 'Location & Logistics';

  @override
  String get labelHome => 'Home';

  @override
  String get labelStudyDestinations => 'Study destinations';

  @override
  String get labelLanguageOfInstruction => 'Language of instruction';

  @override
  String get sectionFinancial => 'Financial';

  @override
  String get labelAnnualBudget => 'Annual budget';

  @override
  String get labelHouseholdIncome => 'Household income';

  @override
  String get labelScholarships => 'Scholarships';

  @override
  String get seekingScholarship => 'Seeking scholarship info';

  @override
  String get notSeekingScholarship => 'Not currently seeking';

  @override
  String get sectionAssessment => 'Assessment';

  @override
  String get labelCareerGoal => 'Career goal';

  @override
  String get labelStrengths => 'Strengths';

  @override
  String get labelInterests => 'Interests';

  @override
  String get labelGpa => 'GPA';

  @override
  String get labelTestScores => 'Test scores';

  @override
  String get addBioPrompt =>
      'Add a short bio so students and counsellors can learn more about you.';

  @override
  String get add => 'Add';

  @override
  String get about => 'About';

  @override
  String get showLess => 'Show less';

  @override
  String get readMore => 'Read more';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String get photoUpdated => 'Profile photo updated';

  @override
  String photoUploadFailed(String error) {
    return 'Could not upload photo: $error';
  }

  @override
  String get photoPermissionDenied =>
      'Photo access was denied. Allow it in your device settings and try again.';

  @override
  String get statFollowers => 'Followers';

  @override
  String get statFollowing => 'Following';

  @override
  String get statPosts => 'Posts';

  @override
  String get roleVerifiedCounsellor => 'Verified Counsellor';

  @override
  String get academicProfile => 'Academic Profile';

  @override
  String get fullDetails => 'Full details';

  @override
  String get labelEducation => 'Education';

  @override
  String get labelDegreeGoal => 'Degree goal';

  @override
  String get labelFieldOfInterest => 'Field of interest';

  @override
  String savedUniversityOne(int count) {
    return '$count saved university';
  }

  @override
  String savedUniversityMany(int count) {
    return '$count saved universities';
  }

  @override
  String get saveUniversitiesCta => 'Save universities to build your shortlist';

  @override
  String get postsTitle => 'Posts';

  @override
  String get shareYourJourney => 'Share your journey';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get postsJourneyMessage =>
      'Posts about your study-abroad journey will appear here.';

  @override
  String get studentNoPostsMessage =>
      'This student has not posted anything yet.';

  @override
  String get writeFirstPost => 'Write your first post';

  @override
  String get postOptions => 'Post options';

  @override
  String get editPost => 'Edit post';

  @override
  String get whatOnYourMind => 'What is on your mind?';

  @override
  String get deletePostTitle => 'Delete post?';

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String couldNotUpdateLike(String error) {
    return 'Could not update like: $error';
  }

  @override
  String couldNotSaveChanges(String error) {
    return 'Could not save changes: $error';
  }

  @override
  String couldNotDeletePost(String error) {
    return 'Could not delete post: $error';
  }

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get notFollowingAnyone => 'Not following anyone yet';

  @override
  String get followersEmptyMessage =>
      'When other students and counsellors follow you, they will show up here.';

  @override
  String get followingEmptyMessage =>
      'Follow students and counsellors to see their activity in your feed.';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String couldNotSaveProfile(String error) {
    return 'Could not save your profile: $error';
  }

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get bioTooLong => 'Bio must be 250 characters or fewer';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get labelFullName => 'Full name';

  @override
  String get fullNameHint => 'e.g. Ada Lovelace';

  @override
  String get labelCountry => 'Country';

  @override
  String get tapToSelectCountry => 'Tap to select your country';

  @override
  String get labelCity => 'City';

  @override
  String get cityHint => 'e.g. Lagos';

  @override
  String get labelBio => 'Bio';

  @override
  String get bioHint =>
      'e.g. Aspiring software engineer passionate about renewable energy';

  @override
  String get academicInformation => 'Academic Information';

  @override
  String get yourCustomField => 'Your custom field';

  @override
  String get customFieldHint => 'Enter your field of interest...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get noProfileFound => 'No profile found';

  @override
  String get completeOnboardingFirst =>
      'Complete the onboarding first so you have a profile to edit.';

  @override
  String get completeMyProfile => 'Complete my profile';

  @override
  String get couldNotLoadYourProfile => 'Could not load your profile';

  @override
  String get accountSection => 'Account';

  @override
  String get labelEmail => 'Email';

  @override
  String get notAvailable => 'Not available';

  @override
  String get changePassword => 'Change password';

  @override
  String get passwordResetHint => 'We will email you a reset link';

  @override
  String get linkedGoogle => 'Linked Google account';

  @override
  String get linked => 'Linked';

  @override
  String get notLinked => 'Not linked';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get settingNewFollowers => 'New followers';

  @override
  String get settingMessages => 'Messages';

  @override
  String get settingClassroomActivity => 'Classroom activity';

  @override
  String get settingBookingReminders => 'Booking reminders';

  @override
  String get languageSection => 'Language';

  @override
  String get languagePreference => 'Language preference';

  @override
  String get privacySection => 'Privacy';

  @override
  String get whoCanMessageYou => 'Who can message you';

  @override
  String get everyone => 'Everyone';

  @override
  String get followersOnly => 'Followers only';

  @override
  String get showSavedUniversities => 'Show my saved universities';

  @override
  String get accountActions => 'Account actions';

  @override
  String get logout => 'Logout';

  @override
  String get logoutHint => 'Sign out of this device';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint => 'Permanently remove your profile and data';

  @override
  String get dataSafetyNote =>
      'Orientaa keeps your data safe. Deleting your account is permanent.';

  @override
  String get resetPasswordTitle => 'Reset your password?';

  @override
  String resetPasswordMessage(String email) {
    return 'We will send a password reset link to $email.';
  }

  @override
  String get sendLink => 'Send link';

  @override
  String passwordResetSent(String email) {
    return 'Password reset link sent to $email';
  }

  @override
  String couldNotSendReset(String error) {
    return 'Could not send reset link: $error';
  }

  @override
  String get noEmailOnAccount => 'No email address on this account';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again to access your profile.';

  @override
  String get logOut => 'Log out';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmMessage =>
      'This permanently removes your profile, posts and settings. Type your email to confirm:';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get emailDoesNotMatch => 'Email does not match';

  @override
  String get requiresRecentLogin =>
      'Please sign in again, then try deleting your account.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Could not delete account: $error';
  }

  @override
  String couldNotSaveSetting(String error) {
    return 'Could not save setting: $error';
  }

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themePreference => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get newMessage => 'New message';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get startConversationPrompt =>
      'Start a conversation with a student or counsellor.';

  @override
  String get you => 'You';

  @override
  String get messagesPrivacyBlocked =>
      'This user only accepts messages from people they follow.';

  @override
  String get searchUsersHint => 'Search students and counsellors...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get searchByNamePrompt => 'Search by name to start a conversation';

  @override
  String get counsellorSessionChip => 'Counsellor Session';

  @override
  String sayHello(String name) {
    return 'Say hello to $name!';
  }

  @override
  String get conversationStart => 'This is the start of your conversation.';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String couldNotSendMessage(String error) {
    return 'Could not send message: $error';
  }

  @override
  String get newPost => 'New Post';

  @override
  String get postHint => 'What\'s on your mind?';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get removeImage => 'Remove image';

  @override
  String get publishPost => 'Post';

  @override
  String get posting => 'Posting...';

  @override
  String get postPublished => 'Your post was published.';

  @override
  String couldNotPublishPost(String error) {
    return 'Could not publish your post: $error';
  }

  @override
  String get writeSomethingFirst => 'Write something before posting.';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get next => 'Next';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get continueAction => 'Continue';

  @override
  String get welcomeTitle => 'Welcome to Orientaa';

  @override
  String get welcomeSubtitle => 'Your career. Your future.';

  @override
  String get welcomeChipExplore => 'Explore';

  @override
  String get welcomeChipCompare => 'Compare';

  @override
  String get welcomeChipGetMatched => 'Get matched';

  @override
  String get welcomeFindPathTitle => 'Find your path';

  @override
  String get welcomeFindPathSubtitle =>
      'Discover universities, courses and scholarships across Africa and the world — tailored to you.';

  @override
  String get welcomeReadyTitle => 'Ready to begin?';

  @override
  String get welcomeReadySubtitle =>
      'Create your account in minutes and start exploring opportunities built around your goals.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccountLogin => 'I already have an account — Log in';

  @override
  String get onboardingWelcomeTitle => 'Welcome, explorer!';

  @override
  String get onboardingWelcomeSubtitle =>
      'Answer a few questions and Orientaa will chart your path to studying anywhere in the world.';

  @override
  String get onboardingChipTailored => 'Tailored matches';

  @override
  String get onboardingChipScholarships => 'Scholarships';

  @override
  String get onboardingChipExpert => 'Expert guidance';

  @override
  String get howWillYouUse => 'How will you use Orientaa?';

  @override
  String get pickRoleSubtitle =>
      'Pick your role to personalize your experience';

  @override
  String get selectRoleToContinue => 'Select a role to continue';

  @override
  String get roleStudentDescription =>
      'Explore universities, courses, scholarships, and manage your academic journey.';

  @override
  String get roleCounsellorDescription =>
      'Guide students, manage counselling sessions, and support their educational success.';

  @override
  String selectRoleSemantics(String role) {
    return 'Select $role role';
  }

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Log in to continue your journey';

  @override
  String get labelPassword => 'Password';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get logIn => 'Log In';

  @override
  String get sendSignInLinkPasswordless => 'Send Sign-In Link (Passwordless)';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String get pleaseEnterEmailToComplete =>
      'Please enter your email to complete sign-in.';

  @override
  String get signedInWithEmailLink => 'Successfully signed in with email link.';

  @override
  String emailLinkSignInFailed(String error) {
    return 'Email link sign-in failed: $error';
  }

  @override
  String get confirmYourEmail => 'Confirm your email';

  @override
  String signInLinkSent(String email) {
    return 'Sign-in link sent to $email';
  }

  @override
  String get enterValidEmailForLink =>
      'Enter a valid email to receive a sign-in link';

  @override
  String failedToSendSignInLink(String error) {
    return 'Failed to send sign-in link: $error';
  }

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String emailNotVerified(String email) {
    return 'Email not verified. A new verification email has been sent to $email. Please check your inbox (and spam folder) and click the verification link.';
  }

  @override
  String get googleSignInSuccessful => 'Google sign-in successful';

  @override
  String verificationResent(String email) {
    return 'Verification email re-sent to $email. Please check your inbox.';
  }

  @override
  String failedToResendVerification(String error) {
    return 'Failed to resend verification: $error';
  }

  @override
  String get emailExampleHint => 'you@example.com';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get signupSubtitle => 'Start your journey with Orientaa';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get enterAPassword => 'Enter a password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String verificationEmailSentTo(String email) {
    return 'Verification email sent to $email. Please verify your email before logging in.';
  }

  @override
  String get resetPasswordHeader => 'Reset password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email and we will send a reset link';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get resetEmailSent => 'Password reset email sent. Check your inbox.';
}
