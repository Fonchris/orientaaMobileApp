// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get tabSaved => 'Enregistrés';

  @override
  String get discoverTitle => 'Découvrir';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String get refresh => 'Actualiser';

  @override
  String get offlineShowingCached =>
      'Vous êtes hors ligne — affichage des derniers résultats enregistrés';

  @override
  String get completeProfileCtaTitle => 'Complétez votre profil';

  @override
  String get completeProfileCtaMessage =>
      'Complétez votre profil pour recevoir des recommandations personnalisées';

  @override
  String get completeProfileButton => 'Compléter le profil';

  @override
  String get couldNotLoadRecommendations =>
      'Impossible de charger les recommandations';

  @override
  String get upgradeToSeeAllRecommendations =>
      'Passez à l\'offre supérieure pour voir toutes les recommandations';

  @override
  String get filterCountry => 'Pays / Région';

  @override
  String get filterDegreeLevel => 'Niveau du diplôme';

  @override
  String get filterFeeRange => 'Frais annuels';

  @override
  String get filterFieldOfStudy => 'Domaine d\'études';

  @override
  String get filterLanguage => 'Langue d\'enseignement';

  @override
  String get fieldsShort => 'domaines';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get compare => 'Comparer';

  @override
  String compareSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get tryAdjustingFilters => 'Essayez d\'ajuster vos filtres';

  @override
  String get upgradeToSeeAllMatches =>
      'Passez à l\'offre supérieure pour voir toutes les correspondances';

  @override
  String get applyFilters => 'Appliquer les filtres';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get savedTitle => 'Enregistrés';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get savedEmptyTitle => 'Aucune université enregistrée';

  @override
  String get savedEmptyMessage =>
      'Appuyez sur le signet d\'une université pour créer votre liste.';

  @override
  String get exploreUniversities => 'Explorer les universités';

  @override
  String get folderEmptyTitle => 'Aucun élément dans ce dossier';

  @override
  String get aboutThisUniversity => 'À propos de cette université';

  @override
  String get programsTitle => 'Programmes';

  @override
  String get locationSection => 'Localisation';

  @override
  String get mapNotAvailable => 'Aperçu de la carte indisponible';

  @override
  String get studentsAlsoViewed =>
      'Les étudiants comme vous ont aussi consulté';

  @override
  String get lockedAlsoViewedMessage =>
      'Passez à Pro ou Premium pour découvrir ce que des étudiants comme vous ont consulté.';

  @override
  String get bookCounselorSession =>
      'Réserver une séance avec un conseiller sur cette université';

  @override
  String get counselorBookingTitle => 'Réservation de conseiller';

  @override
  String get counselorBookingMessage =>
      'La réservation fait partie d\'un module séparé à venir.';

  @override
  String get gotIt => 'Compris';

  @override
  String get compareStubMessage =>
      'La comparaison côte à côte arrive bientôt. Voici vos programmes sélectionnés.';

  @override
  String get sortRelevance => 'Pertinence';

  @override
  String get sortFeeAsc => 'Frais : croissants';

  @override
  String get sortAlphabetical => 'Université A–Z';

  @override
  String couldNotUpdateSaved(String error) {
    return 'Impossible de mettre à jour les universités enregistrées : $error';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get back => 'Retour';

  @override
  String get close => 'Fermer';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSearch => 'Recherche';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabProfile => 'Profil';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotificationsYet => 'Aucune notification';

  @override
  String get recommendedUniversities => 'Universités recommandées';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get noRecommendationsTitle => 'Aucune recommandation';

  @override
  String get noRecommendationsMessage =>
      'Les universités correspondant à votre profil apparaîtront ici dès que notre catalogue sera en ligne.';

  @override
  String get counsellorSession => 'Session conseiller';

  @override
  String get noSessionsScheduled => 'Aucune session planifiée';

  @override
  String get noUpcomingSessions => 'Aucune session à venir';

  @override
  String get sessionsCounsellorEmpty =>
      'Les sessions que vous réservez avec des étudiants s\'afficheront ici.';

  @override
  String get sessionsStudentEmpty =>
      'Réservez une session avec un conseiller et elle sera affichée ici pour ne jamais la manquer.';

  @override
  String get upcoming => 'À venir';

  @override
  String get booked => 'réservé';

  @override
  String get suggestedClassrooms => 'Classes suggérées';

  @override
  String get noClassroomsYet => 'Aucune classe pour le moment';

  @override
  String get noClassroomsMessage =>
      'Les classes correspondant à vos centres d\'intérêt seront suggérées ici.';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get nothingNewYet => 'Rien de nouveau';

  @override
  String get activityMessage =>
      'L\'activité des personnes que vous suivez — nouveaux posts, abonnements et mises à jour de sessions — apparaîtra ici.';

  @override
  String get searchTitle => 'Recherche';

  @override
  String get searchHint => 'Rechercher des personnes, universités, classes...';

  @override
  String get clear => 'Effacer';

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get suggestedSearches => 'Recherches suggérées';

  @override
  String get trendingSearches => 'Tendances';

  @override
  String get nothingHereYet => 'Rien pour le moment';

  @override
  String get tabPeople => 'Personnes';

  @override
  String get tabUniversities => 'Universités';

  @override
  String get tabClassrooms => 'Classes';

  @override
  String get tabPosts => 'Posts';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterStudents => 'Étudiants';

  @override
  String get filterCounsellors => 'Conseillers';

  @override
  String get noUniversitiesFound => 'Aucune université trouvée';

  @override
  String get noClassroomsFound => 'Aucune classe trouvée';

  @override
  String noPeopleFound(String query) {
    return 'Aucune personne trouvée pour \"$query\"';
  }

  @override
  String noPostsFound(String query) {
    return 'Aucun post trouvé pour \"$query\"';
  }

  @override
  String get tryDifferentKeyword =>
      'Essayez un autre mot-clé ou vérifiez l\'orthographe.';

  @override
  String get roleStudent => 'Étudiant';

  @override
  String get roleCounsellor => 'Conseiller';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get profileTitle => 'Profil';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String get profileNotFoundMessage =>
      'Cet utilisateur a peut-être supprimé son compte.';

  @override
  String get couldNotLoadProfile => 'Impossible de charger ce profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get share => 'Partager';

  @override
  String get follow => 'Suivre';

  @override
  String get following => 'Abonné';

  @override
  String get message => 'Message';

  @override
  String get profileLinkCopied => 'Lien du profil copié dans le presse-papiers';

  @override
  String get fullProfileDetails => 'Détails complets du profil';

  @override
  String get sectionAcademic => 'Académique';

  @override
  String get labelEducationLevel => 'Niveau d\'études';

  @override
  String get labelDesiredDegree => 'Diplôme visé';

  @override
  String get labelFieldsOfInterest => 'Domaines d\'intérêt';

  @override
  String get labelPlannedStart => 'Début prévu';

  @override
  String get sectionLocationLogistics => 'Lieu et logistique';

  @override
  String get labelHome => 'Pays d\'origine';

  @override
  String get labelStudyDestinations => 'Destinations d\'études';

  @override
  String get labelLanguageOfInstruction => 'Langue d\'enseignement';

  @override
  String get sectionFinancial => 'Financement';

  @override
  String get labelAnnualBudget => 'Budget annuel';

  @override
  String get labelHouseholdIncome => 'Revenu du foyer';

  @override
  String get labelScholarships => 'Bourses';

  @override
  String get seekingScholarship => 'Recherche d\'informations sur les bourses';

  @override
  String get notSeekingScholarship => 'Pas de recherche actuellement';

  @override
  String get sectionAssessment => 'Évaluation';

  @override
  String get labelCareerGoal => 'Objectif de carrière';

  @override
  String get labelStrengths => 'Points forts';

  @override
  String get labelInterests => 'Centres d\'intérêt';

  @override
  String get labelGpa => 'Moyenne (GPA)';

  @override
  String get labelTestScores => 'Scores aux tests';

  @override
  String get addBioPrompt =>
      'Ajoutez une courte bio pour que les étudiants et conseillers puissent mieux vous connaître.';

  @override
  String get add => 'Ajouter';

  @override
  String get about => 'À propos';

  @override
  String get showLess => 'Voir moins';

  @override
  String get readMore => 'Lire plus';

  @override
  String get changeProfilePhoto => 'Changer la photo de profil';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get uploadingPhoto => 'Téléversement de la photo...';

  @override
  String get photoUpdated => 'Photo de profil mise à jour';

  @override
  String photoUploadFailed(String error) {
    return 'Impossible de téléverser la photo : $error';
  }

  @override
  String get photoPermissionDenied =>
      'L\'accès aux photos a été refusé. Autorisez-le dans les réglages de votre appareil puis réessayez.';

  @override
  String get statFollowers => 'Abonnés';

  @override
  String get statFollowing => 'Abonnements';

  @override
  String get statPosts => 'Posts';

  @override
  String get roleVerifiedCounsellor => 'Conseiller vérifié';

  @override
  String get academicProfile => 'Profil académique';

  @override
  String get fullDetails => 'Détails complets';

  @override
  String get labelEducation => 'Études';

  @override
  String get labelDegreeGoal => 'Diplôme visé';

  @override
  String get labelFieldOfInterest => 'Domaine d\'intérêt';

  @override
  String savedUniversityOne(int count) {
    return '$count université enregistrée';
  }

  @override
  String savedUniversityMany(int count) {
    return '$count universités enregistrées';
  }

  @override
  String get saveUniversitiesCta =>
      'Enregistrez des universités pour constituer votre liste';

  @override
  String get postsTitle => 'Posts';

  @override
  String get shareYourJourney => 'Partagez votre parcours';

  @override
  String get noPostsYet => 'Aucun post';

  @override
  String get postsJourneyMessage =>
      'Les posts sur votre parcours d\'études à l\'étranger apparaîtront ici.';

  @override
  String get studentNoPostsMessage => 'Cet étudiant n\'a encore rien publié.';

  @override
  String get writeFirstPost => 'Écrire votre premier post';

  @override
  String get postOptions => 'Options du post';

  @override
  String get editPost => 'Modifier le post';

  @override
  String get whatOnYourMind => 'Qu\'avez-vous en tête ?';

  @override
  String get deletePostTitle => 'Supprimer le post ?';

  @override
  String get cannotUndo => 'Cette action est irréversible.';

  @override
  String couldNotUpdateLike(String error) {
    return 'Impossible de mettre à jour le j\'aime : $error';
  }

  @override
  String couldNotSaveChanges(String error) {
    return 'Impossible d\'enregistrer les modifications : $error';
  }

  @override
  String couldNotDeletePost(String error) {
    return 'Impossible de supprimer le post : $error';
  }

  @override
  String get noFollowersYet => 'Aucun abonné pour le moment';

  @override
  String get notFollowingAnyone => 'Vous ne suivez personne';

  @override
  String get followersEmptyMessage =>
      'Lorsque des étudiants et conseillers vous suivront, ils apparaîtront ici.';

  @override
  String get followingEmptyMessage =>
      'Suivez des étudiants et conseillers pour voir leur activité dans votre fil.';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String couldNotSaveProfile(String error) {
    return 'Impossible d\'enregistrer votre profil : $error';
  }

  @override
  String get fullNameRequired => 'Le nom complet est requis';

  @override
  String get bioTooLong => 'La bio doit faire 250 caractères ou moins';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get labelFullName => 'Nom complet';

  @override
  String get fullNameHint => 'ex. Ada Lovelace';

  @override
  String get labelCountry => 'Pays';

  @override
  String get tapToSelectCountry => 'Touchez pour sélectionner votre pays';

  @override
  String get labelCity => 'Ville';

  @override
  String get cityHint => 'ex. Lagos';

  @override
  String get labelBio => 'Bio';

  @override
  String get bioHint =>
      'ex. Ingénieure logiciel passionnée par les énergies renouvelables';

  @override
  String get academicInformation => 'Informations académiques';

  @override
  String get yourCustomField => 'Votre domaine personnalisé';

  @override
  String get customFieldHint => 'Entrez votre domaine d\'intérêt...';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get noProfileFound => 'Aucun profil trouvé';

  @override
  String get completeOnboardingFirst =>
      'Terminez d\'abord l\'onboarding pour avoir un profil à modifier.';

  @override
  String get completeMyProfile => 'Compléter mon profil';

  @override
  String get couldNotLoadYourProfile => 'Impossible de charger votre profil';

  @override
  String get accountSection => 'Compte';

  @override
  String get labelEmail => 'E-mail';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get passwordResetHint =>
      'Nous vous enverrons un lien de réinitialisation par e-mail';

  @override
  String get linkedGoogle => 'Compte Google lié';

  @override
  String get linked => 'Lié';

  @override
  String get notLinked => 'Non lié';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get settingNewFollowers => 'Nouveaux abonnés';

  @override
  String get settingMessages => 'Messages';

  @override
  String get settingClassroomActivity => 'Activité des classes';

  @override
  String get settingBookingReminders => 'Rappels de réservation';

  @override
  String get languageSection => 'Langue';

  @override
  String get languagePreference => 'Langue préférée';

  @override
  String get privacySection => 'Confidentialité';

  @override
  String get whoCanMessageYou => 'Qui peut vous écrire';

  @override
  String get everyone => 'Tout le monde';

  @override
  String get followersOnly => 'Abonnés uniquement';

  @override
  String get showSavedUniversities => 'Afficher mes universités enregistrées';

  @override
  String get accountActions => 'Actions du compte';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutHint => 'Se déconnecter de cet appareil';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountHint =>
      'Supprimer définitivement votre profil et vos données';

  @override
  String get dataSafetyNote =>
      'Orientaa protège vos données. La suppression du compte est définitive.';

  @override
  String get resetPasswordTitle => 'Réinitialiser votre mot de passe ?';

  @override
  String resetPasswordMessage(String email) {
    return 'Nous enverrons un lien de réinitialisation à $email.';
  }

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String passwordResetSent(String email) {
    return 'Lien de réinitialisation envoyé à $email';
  }

  @override
  String couldNotSendReset(String error) {
    return 'Impossible d\'envoyer le lien de réinitialisation : $error';
  }

  @override
  String get noEmailOnAccount => 'Aucune adresse e-mail sur ce compte';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmMessage =>
      'Vous devrez vous reconnecter pour accéder à votre profil.';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cela supprime définitivement votre profil, vos posts et vos paramètres. Saisissez votre e-mail pour confirmer :';

  @override
  String get enterYourEmail => 'Entrez votre e-mail';

  @override
  String get emailDoesNotMatch => 'L\'e-mail ne correspond pas';

  @override
  String get requiresRecentLogin =>
      'Veuillez vous reconnecter, puis réessayez de supprimer votre compte.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Impossible de supprimer le compte : $error';
  }

  @override
  String couldNotSaveSetting(String error) {
    return 'Impossible d\'enregistrer le réglage : $error';
  }

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get themePreference => 'Thème';

  @override
  String get themeSystem => 'Par défaut';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get noMessagesYet => 'Aucun message';

  @override
  String get startConversationPrompt =>
      'Commencez une conversation avec un étudiant ou un conseiller.';

  @override
  String get you => 'Vous';

  @override
  String get messagesPrivacyBlocked =>
      'Cet utilisateur n\'accepte les messages que des personnes qu\'il suit.';

  @override
  String get searchUsersHint => 'Rechercher des étudiants et conseillers...';

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get searchByNamePrompt =>
      'Recherchez par nom pour commencer une conversation';

  @override
  String get counsellorSessionChip => 'Session conseiller';

  @override
  String sayHello(String name) {
    return 'Dites bonjour à $name !';
  }

  @override
  String get conversationStart => 'C\'est le début de votre conversation.';

  @override
  String get writeMessage => 'Écrivez un message...';

  @override
  String couldNotSendMessage(String error) {
    return 'Impossible d\'envoyer le message : $error';
  }

  @override
  String get newPost => 'Nouveau post';

  @override
  String get postHint => 'Qu\'avez-vous en tête ?';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get removeImage => 'Retirer l\'image';

  @override
  String get publishPost => 'Publier';

  @override
  String get posting => 'Publication...';

  @override
  String get postPublished => 'Votre post a été publié.';

  @override
  String couldNotPublishPost(String error) {
    return 'Impossible de publier votre post : $error';
  }

  @override
  String get writeSomethingFirst => 'Écrivez quelque chose avant de publier.';

  @override
  String uploadFailed(String error) {
    return 'Échec du téléversement : $error';
  }

  @override
  String get next => 'Suivant';

  @override
  String get toggleTheme => 'Changer de thème';

  @override
  String get continueAction => 'Continuer';

  @override
  String get welcomeTitle => 'Bienvenue sur Orientaa';

  @override
  String get welcomeSubtitle => 'Votre carrière. Votre avenir.';

  @override
  String get welcomeChipExplore => 'Explorer';

  @override
  String get welcomeChipCompare => 'Comparer';

  @override
  String get welcomeChipGetMatched => 'Être mis en relation';

  @override
  String get welcomeFindPathTitle => 'Trouvez votre voie';

  @override
  String get welcomeFindPathSubtitle =>
      'Découvrez des universités, des cursus et des bourses en Afrique et dans le monde — adaptés à vous.';

  @override
  String get welcomeReadyTitle => 'Prêt à commencer ?';

  @override
  String get welcomeReadySubtitle =>
      'Créez votre compte en quelques minutes et commencez à explorer des opportunités alignées sur vos objectifs.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get alreadyHaveAccountLogin => 'J\'ai déjà un compte — Se connecter';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue, explorateur !';

  @override
  String get onboardingWelcomeSubtitle =>
      'Répondez à quelques questions et Orientaa tracera votre parcours vers des études partout dans le monde.';

  @override
  String get onboardingChipTailored => 'Correspondances sur mesure';

  @override
  String get onboardingChipScholarships => 'Bourses';

  @override
  String get onboardingChipExpert => 'Conseils d\'experts';

  @override
  String get howWillYouUse => 'Comment utiliserez-vous Orientaa ?';

  @override
  String get pickRoleSubtitle =>
      'Choisissez votre rôle pour personnaliser votre expérience';

  @override
  String get selectRoleToContinue => 'Sélectionnez un rôle pour continuer';

  @override
  String get roleStudentDescription =>
      'Explorez les universités, les cursus, les bourses et gérez votre parcours académique.';

  @override
  String get roleCounsellorDescription =>
      'Guidez les étudiants, gérez les séances d\'orientation et soutenez leur réussite scolaire.';

  @override
  String selectRoleSemantics(String role) {
    return 'Sélectionner le rôle $role';
  }

  @override
  String get loginWelcomeBack => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connectez-vous pour poursuivre votre parcours';

  @override
  String get labelPassword => 'Mot de passe';

  @override
  String get enterValidEmail => 'Entrez un email valide';

  @override
  String get enterYourPassword => 'Entrez votre mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get logIn => 'Se connecter';

  @override
  String get sendSignInLinkPasswordless =>
      'Envoyer un lien de connexion (sans mot de passe)';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get dontHaveAccount => 'Pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get resendVerificationEmail => 'Renvoyer l\'email de vérification';

  @override
  String get pleaseEnterEmailToComplete =>
      'Veuillez saisir votre email pour terminer la connexion.';

  @override
  String get signedInWithEmailLink => 'Connexion réussie avec le lien email.';

  @override
  String emailLinkSignInFailed(String error) {
    return 'Échec de la connexion par lien email : $error';
  }

  @override
  String get confirmYourEmail => 'Confirmez votre email';

  @override
  String signInLinkSent(String email) {
    return 'Lien de connexion envoyé à $email';
  }

  @override
  String get enterValidEmailForLink =>
      'Entrez un email valide pour recevoir un lien de connexion';

  @override
  String failedToSendSignInLink(String error) {
    return 'Échec de l\'envoi du lien de connexion : $error';
  }

  @override
  String get loginSuccessful => 'Connexion réussie';

  @override
  String emailNotVerified(String email) {
    return 'Email non vérifié. Un nouvel email de vérification a été envoyé à $email. Vérifiez votre boîte de réception (et vos spams) et cliquez sur le lien de vérification.';
  }

  @override
  String get googleSignInSuccessful => 'Connexion Google réussie';

  @override
  String verificationResent(String email) {
    return 'Email de vérification renvoyé à $email. Vérifiez votre boîte de réception.';
  }

  @override
  String failedToResendVerification(String error) {
    return 'Échec du renvoi de la vérification : $error';
  }

  @override
  String get emailExampleHint => 'vous@exemple.com';

  @override
  String get createAccountTitle => 'Créer un compte';

  @override
  String get signupSubtitle => 'Commencez votre parcours avec Orientaa';

  @override
  String get enterYourFullName => 'Entrez votre nom complet';

  @override
  String get enterAPassword => 'Entrez un mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String verificationEmailSentTo(String email) {
    return 'Email de vérification envoyé à $email. Veuillez vérifier votre email avant de vous connecter.';
  }

  @override
  String get resetPasswordHeader => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordSubtitle =>
      'Entrez votre email et nous enverrons un lien de réinitialisation';

  @override
  String get sendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get resetEmailSent =>
      'Email de réinitialisation envoyé. Vérifiez votre boîte de réception.';
}
