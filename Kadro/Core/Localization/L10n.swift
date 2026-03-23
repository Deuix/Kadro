//
//  L10n.swift
//  Kadro
//
//  Type-safe localization access for all app strings.
//
//  Usage:
//    Text(L10n.Home.createContent)          // in SwiftUI views
//    .navigationTitle(L10n.Settings.title)  // string contexts
//

import Foundation

// MARK: - L10n

enum L10n {
    private static func s(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: Common

    enum Common {
        static var save: String           { L10n.s("common.save") }
        static var cancel: String         { L10n.s("common.cancel") }
        static var delete: String         { L10n.s("common.delete") }
        static var ok: String             { L10n.s("common.ok") }
        static var close: String          { L10n.s("common.close") }
        static var done: String           { L10n.s("common.done") }
        static var all: String            { L10n.s("common.all") }
        static var untitled: String       { L10n.s("common.untitled") }
        static var create: String         { L10n.s("common.create") }
        static var continueAction: String { L10n.s("common.continue") }
        static var next: String           { L10n.s("common.next") }
        static var errorTitle: String     { L10n.s("common.error_title") }
        static var errorMessage: String   { L10n.s("common.error_message") }
    }

    // MARK: Tabs

    enum Tab {
        static var home: String     { L10n.s("tab.home") }
        static var create: String   { L10n.s("tab.create") }
        static var content: String  { L10n.s("tab.content") }
        static var calendar: String { L10n.s("tab.calendar") }
        static var profile: String  { L10n.s("tab.profile") }
    }

    // MARK: Home

    enum Home {
        static var greetingNight: String      { L10n.s("home.greeting_night") }
        static var greetingMorning: String    { L10n.s("home.greeting_morning") }
        static var greetingAfternoon: String  { L10n.s("home.greeting_afternoon") }
        static var greetingEvening: String    { L10n.s("home.greeting_evening") }
        static var creatorBadge: String       { L10n.s("home.creator_badge") }
        static var createContent: String      { L10n.s("home.create_content") }
        static var createContentSubtitle: String { L10n.s("home.create_content_subtitle") }
        static var carousel: String           { L10n.s("home.carousel") }
        static var reels: String              { L10n.s("home.reels") }
        static var drafts: String             { L10n.s("home.drafts") }
        static var all: String                { L10n.s("home.all") }
        static var createFirstProject: String { L10n.s("home.create_first_project") }
        static var contentIdeas: String       { L10n.s("home.content_ideas") }
        static var ideaEducationTag: String   { L10n.s("home.idea_education_tag") }
        static var ideaPersonalTag: String    { L10n.s("home.idea_personal_tag") }
        static var ideaSalesTag: String       { L10n.s("home.idea_sales_tag") }
        static var ideaShareExpertise: String { L10n.s("home.idea_share_expertise") }
        static var ideaPersonalStory: String  { L10n.s("home.idea_personal_story") }
        static var ideaShowResults: String    { L10n.s("home.idea_show_results") }
    }

    // MARK: Settings

    enum Settings {
        static var title: String                { L10n.s("settings.title") }
        static var sectionAccount: String       { L10n.s("settings.section_account") }
        static var profile: String              { L10n.s("settings.profile") }
        static var email: String                { L10n.s("settings.email") }
        static var emailNotLinked: String       { L10n.s("settings.email_not_linked") }
        static var sectionSubscription: String  { L10n.s("settings.section_subscription") }
        static var kadroPro: String             { L10n.s("settings.kadro_pro") }
        static var freePlan: String             { L10n.s("settings.free_plan") }
        static var restorePurchases: String     { L10n.s("settings.restore_purchases") }
        static var sectionApp: String           { L10n.s("settings.section_app") }
        static var language: String             { L10n.s("settings.language") }
        static var notifications: String        { L10n.s("settings.notifications") }
        static var exportData: String           { L10n.s("settings.export_data") }
        static var sectionConnections: String   { L10n.s("settings.section_connections") }
        static var connectedPlatforms: String   { L10n.s("settings.connected_platforms") }
        static var sectionSupport: String       { L10n.s("settings.section_support") }
        static var helpFaq: String              { L10n.s("settings.help_faq") }
        static var contactUs: String            { L10n.s("settings.contact_us") }
        static var rateApp: String              { L10n.s("settings.rate_app") }
        static var sectionAbout: String         { L10n.s("settings.section_about") }
        static var version: String              { L10n.s("settings.version") }
        static var terms: String                { L10n.s("settings.terms") }
        static var privacy: String              { L10n.s("settings.privacy") }
        static var resetOnboarding: String      { L10n.s("settings.reset_onboarding") }
        static var copyright: String            { L10n.s("settings.copyright") }
        static var resetConfirmTitle: String    { L10n.s("settings.reset_confirm_title") }
        static var resetConfirmMessage: String  { L10n.s("settings.reset_confirm_message") }
        static var resetAction: String          { L10n.s("settings.reset_action") }
        static var sectionAppearance: String    { L10n.s("settings.section_appearance") }
        static var themeLabel: String           { L10n.s("settings.theme_label") }
    }

    // MARK: Onboarding

    enum Onboarding {
        static var step1Headline: String       { L10n.s("onboarding.step1_headline") }
        static var step1Subtitle: String       { L10n.s("onboarding.step1_subtitle") }
        static var feature1: String            { L10n.s("onboarding.feature1") }
        static var feature2: String            { L10n.s("onboarding.feature2") }
        static var feature3: String            { L10n.s("onboarding.feature3") }
        static var start: String               { L10n.s("onboarding.start") }
        static var continueAction: String      { L10n.s("onboarding.continue") }
        static var step2Title: String          { L10n.s("onboarding.step2_title") }
        static var step2Subtitle: String       { L10n.s("onboarding.step2_subtitle") }
        static var step3Title: String          { L10n.s("onboarding.step3_title") }
        static var step3Subtitle: String       { L10n.s("onboarding.step3_subtitle") }
        static var step4Title: String          { L10n.s("onboarding.step4_title") }
        static var step4Subtitle: String       { L10n.s("onboarding.step4_subtitle") }
        static var toneVoice: String           { L10n.s("onboarding.tone_voice") }
        static var visualStyle: String         { L10n.s("onboarding.visual_style") }
        static var step5Title: String          { L10n.s("onboarding.step5_title") }
        static var step5Subtitle: String       { L10n.s("onboarding.step5_subtitle") }
        static var createFirstContent: String  { L10n.s("onboarding.create_first_content") }
        static var disclaimer: String          { L10n.s("onboarding.disclaimer") }
        // Tone presets
        static var toneFriendly: String        { L10n.s("onboarding.tone_friendly") }
        static var toneExpert: String          { L10n.s("onboarding.tone_expert") }
        static var toneBalanced: String        { L10n.s("onboarding.tone_balanced") }
        static var toneBold: String            { L10n.s("onboarding.tone_bold") }
        // Content goals
        static var goalPosts: String           { L10n.s("onboarding.goal_posts") }
        static var goalCarousels: String       { L10n.s("onboarding.goal_carousels") }
        static var goalReels: String           { L10n.s("onboarding.goal_reels") }
        static var goalContentPlan: String     { L10n.s("onboarding.goal_content_plan") }
    }

    // MARK: Content Library

    enum Content {
        static var title: String              { L10n.s("content.title") }
        static var searchPlaceholder: String  { L10n.s("content.search_placeholder") }
        static var filterAll: String          { L10n.s("content.filter_all") }
        static var emptyTitle: String         { L10n.s("content.empty_title") }
        static var emptySubtitle: String      { L10n.s("content.empty_subtitle") }
        static var createContent: String      { L10n.s("content.create_content") }
        static var noResultsTitle: String     { L10n.s("content.no_results_title") }
        static var noResultsSubtitle: String  { L10n.s("content.no_results_subtitle") }
        static var deleteSwipe: String        { L10n.s("content.delete_swipe") }
        static var deleteConfirmTitle: String { L10n.s("content.delete_confirm_title") }
        static var deleteConfirmAction: String { L10n.s("content.delete_confirm_action") }

        static func deleteConfirmMessage(projectTitle: String) -> String {
            String(format: L10n.s("content.delete_confirm_message"), projectTitle)
        }
    }

    // MARK: Create Flow

    enum Create {
        static var navTitle: String              { L10n.s("create.nav_title") }
        static var stepService: String           { L10n.s("create.step_service") }
        static var stepFormat: String            { L10n.s("create.step_format") }
        static var stepIdea: String              { L10n.s("create.step_idea") }
        static var stepRefine: String            { L10n.s("create.step_refine") }
        static var continueAction: String        { L10n.s("create.continue") }
        static var next: String                  { L10n.s("create.next") }
        static var createPost: String            { L10n.s("create.create_post") }
        static var createStory: String           { L10n.s("create.create_story") }
        static var createCarousel: String        { L10n.s("create.create_carousel") }
        static var createGeneric: String         { L10n.s("create.create_generic") }
        static var loadingVoiceTitle: String     { L10n.s("create.loading_voice_title") }
        static var loadingVoiceSubtitle: String  { L10n.s("create.loading_voice_subtitle") }
        static var loadingContentTitle: String   { L10n.s("create.loading_content_title") }
        static var loadingContentSubtitle: String { L10n.s("create.loading_content_subtitle") }
        // Input sources
        static var sourceTopic: String           { L10n.s("create.source_topic") }
        static var sourceVoiceNote: String       { L10n.s("create.source_voice_note") }
        static var sourceText: String            { L10n.s("create.source_text") }
        // Service subtitles
        static var serviceInstagramSubtitle: String { L10n.s("create.service_instagram_subtitle") }
        static var serviceComingSoon: String     { L10n.s("create.service_coming_soon") }
        // Format subtitles
        static var formatPostSubtitle: String     { L10n.s("create.format_post_subtitle") }
        static var formatStorySubtitle: String    { L10n.s("create.format_story_subtitle") }
        static var formatCarouselSubtitle: String { L10n.s("create.format_carousel_subtitle") }
        // Canvas
        static var canvasSquare: String           { L10n.s("create.canvas_square") }
        static var canvasPortrait: String         { L10n.s("create.canvas_portrait") }
        static var canvasSquareSubtitle: String   { L10n.s("create.canvas_square_subtitle") }
        static var canvasPortraitSubtitle: String { L10n.s("create.canvas_portrait_subtitle") }
        // Step headers
        static func stepEyebrow(_ n: Int) -> String { String(format: L10n.s("create.step_eyebrow"), n) }
        static var step1Title: String             { L10n.s("create.step1_title") }
        static var step1Subtitle: String          { L10n.s("create.step1_subtitle") }
        static var step2Title: String             { L10n.s("create.step2_title") }
        static var step2Subtitle: String          { L10n.s("create.step2_subtitle") }
        static var step3Subtitle: String          { L10n.s("create.step3_subtitle") }
        static var step4Title: String             { L10n.s("create.step4_title") }
        static var step4Subtitle: String          { L10n.s("create.step4_subtitle") }
        // Content language
        static var contentLanguage: String        { L10n.s("create.content_language") }
        static var contentLanguageHint: String    { L10n.s("create.content_language_hint") }
        // Canvas type & slides
        static var canvasType: String             { L10n.s("create.canvas_type") }
        static var slideCount: String             { L10n.s("create.slide_count") }
        static var slideCountHint: String         { L10n.s("create.slide_count_hint") }
        // Idea step
        static var ideaInputLabel: String         { L10n.s("create.idea_input_label") }
        static var ideaPostTitle: String          { L10n.s("create.idea_post_title") }
        static var ideaStoryTitle: String         { L10n.s("create.idea_story_title") }
        static var ideaCarouselTitle: String      { L10n.s("create.idea_carousel_title") }
        static var ideaGenericTitle: String       { L10n.s("create.idea_generic_title") }
        static var ideaPostPlaceholder: String    { L10n.s("create.idea_post_placeholder") }
        static var ideaStoryPlaceholder: String   { L10n.s("create.idea_story_placeholder") }
        static var ideaCarouselPlaceholder: String { L10n.s("create.idea_carousel_placeholder") }
        static var ideaGenericPlaceholder: String { L10n.s("create.idea_generic_placeholder") }
        // Voice recorder
        static var voiceInputTitle: String        { L10n.s("create.voice_input_title") }
        static var voiceInputHint: String         { L10n.s("create.voice_input_hint") }
        static var voiceInputRecordingHint: String { L10n.s("create.voice_input_recording_hint") }
        static var voiceStop: String              { L10n.s("create.voice_stop") }
        static var voiceRecord: String            { L10n.s("create.voice_record") }
        static var voiceTranscribing: String      { L10n.s("create.voice_transcribing") }
        static func voiceRecognized(_ model: String) -> String { String(format: L10n.s("create.voice_recognized"), model) }
        static var voiceAdded: String             { L10n.s("create.voice_added") }
        static func charCount(_ n: Int) -> String { String(format: L10n.s("create.char_count"), n) }
        // Refine step
        static var yourChoices: String            { L10n.s("create.your_choices") }
        static func slidesCount(_ n: Int) -> String { String(format: L10n.s("create.slides_count"), n) }
        static var toneLabel: String              { L10n.s("create.tone_label") }
        static var goalLabel: String              { L10n.s("create.goal_label") }
        static var visualStyle: String            { L10n.s("create.visual_style") }
        static var visualStyleHint: String        { L10n.s("create.visual_style_hint") }
        // Navigation
        static var back: String                   { L10n.s("create.back") }
        static var serviceUnavailable: String     { L10n.s("create.service_unavailable") }
    }

    // MARK: Generated Content

    enum Generated {
        static var navTitle: String           { L10n.s("generated.nav_title") }
        static var hook: String               { L10n.s("generated.hook") }
        static var mainText: String           { L10n.s("generated.main_text") }
        static var cta: String                { L10n.s("generated.cta") }
        static var shortVersion: String       { L10n.s("generated.short_version") }
        static var caption: String            { L10n.s("generated.caption") }
        static var hashtags: String           { L10n.s("generated.hashtags") }
        static var sourceIdea: String         { L10n.s("generated.source_idea") }
        static var onScreenText: String       { L10n.s("generated.on_screen_text") }
        static var coverIdea: String          { L10n.s("generated.cover_idea") }
        static var scriptBeats: String        { L10n.s("generated.script_beats") }
        static var visual: String             { L10n.s("generated.visual") }
        static var visualLoadingTitle: String { L10n.s("generated.visual_loading_title") }
        static var visualLoadingSubtitle: String { L10n.s("generated.visual_loading_subtitle") }
        static var detailVisualLoadingSubtitle: String { L10n.s("generated.detail_visual_loading_subtitle") }
        static var useAsCover: String         { L10n.s("generated.use_as_cover") }
        static var useForSlide: String        { L10n.s("generated.use_for_slide") }
        static var carouselSlides: String     { L10n.s("generated.carousel_slides") }
        static var storiesSection: String     { L10n.s("generated.stories_section") }
        static var variants: String           { L10n.s("generated.variants") }
        static var nextActions: String        { L10n.s("generated.next_actions") }
        static var savedToContent: String     { L10n.s("generated.saved_to_content") }
        static var visualError: String        { L10n.s("generated.visual_error") }
        static var newVersion: String         { L10n.s("generated.new_version") }
        static var reelsSection: String       { L10n.s("generated.reels_section") }
        static var reelsHook: String          { L10n.s("generated.reels_hook") }

        static func stickerFormat(_ idea: String) -> String {
            String(format: L10n.s("generated.sticker_format"), idea)
        }
        static func slideFormat(_ order: Int) -> String {
            String(format: L10n.s("generated.slide_format"), order)
        }
        static func storyFormat(_ index: Int) -> String {
            String(format: L10n.s("generated.story_format"), index)
        }
        // Visual section
        static var postMainText: String           { L10n.s("generated.post_main_text") }
        static var visualSectionPost: String      { L10n.s("generated.visual_section_post") }
        static var visualSectionGeneric: String   { L10n.s("generated.visual_section_generic") }
        static func stylePackLabel(_ name: String) -> String { String(format: L10n.s("generated.style_pack_label"), name) }
        static func referencesFound(_ n: Int) -> String { String(format: L10n.s("generated.references_found"), n) }
        static var noStylePack: String            { L10n.s("generated.no_style_pack") }
        static var createCoverImage: String       { L10n.s("generated.create_cover_image") }
        static var regenerateCoverImage: String   { L10n.s("generated.regenerate_cover_image") }
        static var createCover: String            { L10n.s("generated.create_cover") }
        static var regenerateCover: String        { L10n.s("generated.regenerate_cover") }
        static var allVisuals: String             { L10n.s("generated.all_visuals") }
        static var createSlideVisual: String      { L10n.s("generated.create_slide_visual") }
        static var regenerateSlideVisual: String  { L10n.s("generated.regenerate_slide_visual") }
        static var loadingCoverTitle: String      { L10n.s("generated.loading_cover_title") }
        static var loadingCoverSubtitle: String   { L10n.s("generated.loading_cover_subtitle") }
        static var loadingSlideTitle: String      { L10n.s("generated.loading_slide_title") }
        static func loadingSlideSubtitle(_ order: Int) -> String { String(format: L10n.s("generated.loading_slide_subtitle"), order) }
        static var loadingAllSlidesTitle: String  { L10n.s("generated.loading_all_slides_title") }
        static func loadingAllSlidesSubtitle(_ index: Int, _ total: Int, _ headline: String) -> String {
            String(format: L10n.s("generated.loading_all_slides_subtitle"), index, total, headline)
        }
        static func slideError(_ order: Int, _ message: String) -> String { String(format: L10n.s("generated.slide_error"), order, message) }
        static var downloading: String            { L10n.s("generated.downloading") }
        static var downloadAll: String            { L10n.s("generated.download_all") }
        static var saveVisualError: String        { L10n.s("generated.save_visual_error") }
        static var findSlideError: String         { L10n.s("generated.find_slide_error") }
        static var regeneratingTitle: String      { L10n.s("generated.regenerating_title") }
        static var regeneratingSubtitle: String   { L10n.s("generated.regenerating_subtitle") }
        static var noSourceIdea: String           { L10n.s("generated.no_source_idea") }
        static var detailNoStylePack: String      { L10n.s("generated.detail_no_style_pack") }
        static var copied: String                 { L10n.s("generated.copied") }
        static var storiesDraft: String           { L10n.s("generated.stories_draft") }
        static var visualDraft: String            { L10n.s("generated.visual_draft") }
    }

    // MARK: Brand

    enum Brand {
        static var navTitle: String                 { L10n.s("brand.nav_title") }
        static var save: String                     { L10n.s("brand.save") }
        static var sectionBasics: String            { L10n.s("brand.section_basics") }
        static var brandName: String                { L10n.s("brand.brand_name") }
        static var brandNamePlaceholder: String     { L10n.s("brand.brand_name_placeholder") }
        static var niche: String                    { L10n.s("brand.niche") }
        static var nichePlaceholder: String         { L10n.s("brand.niche_placeholder") }
        static var audience: String                 { L10n.s("brand.audience") }
        static var audiencePlaceholder: String      { L10n.s("brand.audience_placeholder") }
        static var profileType: String              { L10n.s("brand.profile_type") }
        static var toneSection: String              { L10n.s("brand.tone_section") }
        static var toneExpert: String               { L10n.s("brand.tone_expert") }
        static var toneExpertLeft: String           { L10n.s("brand.tone_expert_left") }
        static var toneExpertRight: String          { L10n.s("brand.tone_expert_right") }
        static var toneWarmth: String               { L10n.s("brand.tone_warmth") }
        static var toneWarmthLeft: String           { L10n.s("brand.tone_warmth_left") }
        static var toneWarmthRight: String          { L10n.s("brand.tone_warmth_right") }
        static var toneBoldness: String             { L10n.s("brand.tone_boldness") }
        static var toneBoldnessLeft: String         { L10n.s("brand.tone_boldness_left") }
        static var toneBoldnessRight: String        { L10n.s("brand.tone_boldness_right") }
        static var toneDetail: String               { L10n.s("brand.tone_detail") }
        static var toneDetailLeft: String           { L10n.s("brand.tone_detail_left") }
        static var toneDetailRight: String          { L10n.s("brand.tone_detail_right") }
        static var writingRules: String             { L10n.s("brand.writing_rules") }
        static var wordsToUse: String               { L10n.s("brand.words_to_use") }
        static var wordsToUsePlaceholder: String    { L10n.s("brand.words_to_use_placeholder") }
        static var wordsToAvoid: String             { L10n.s("brand.words_to_avoid") }
        static var wordsToAvoidPlaceholder: String  { L10n.s("brand.words_to_avoid_placeholder") }
        static var ctaStyle: String                 { L10n.s("brand.cta_style") }
        static var ctaStylePlaceholder: String      { L10n.s("brand.cta_style_placeholder") }
        static var favoritePhrases: String          { L10n.s("brand.favorite_phrases") }
        static var favoritePhrasesPlaceholder: String { L10n.s("brand.favorite_phrases_placeholder") }
        static var sectionVisualStyle: String       { L10n.s("brand.section_visual_style") }
        static var stylePacks: String               { L10n.s("brand.style_packs") }
        static var palette: String                  { L10n.s("brand.palette") }
        static var palettePlaceholder: String       { L10n.s("brand.palette_placeholder") }
        static var coverStyle: String               { L10n.s("brand.cover_style") }
        static var coverStylePlaceholder: String    { L10n.s("brand.cover_style_placeholder") }
        static var references: String               { L10n.s("brand.references") }
        static var referencesPlaceholder: String    { L10n.s("brand.references_placeholder") }

        static func selectedStylePack(_ name: String) -> String {
            String(format: L10n.s("brand.selected_style_pack"), name)
        }
    }

    // MARK: App Theme

    enum Theme {
        static var system: String { L10n.s("theme.system") }
        static var light: String  { L10n.s("theme.light") }
        static var dark: String   { L10n.s("theme.dark") }
    }

    // MARK: Calendar

    enum Calendar {
        static var title: String        { L10n.s("calendar.title") }
        static var noContent: String    { L10n.s("calendar.no_content") }
        static var schedule: String     { L10n.s("calendar.schedule") }
        static var hints: String        { L10n.s("calendar.hints") }
        static var hint1: String        { L10n.s("calendar.hint1") }
        static var hint2: String        { L10n.s("calendar.hint2") }
        static var modePickerLabel: String { L10n.s("calendar.mode_picker_label") }
        static var modeWeek: String     { L10n.s("calendar.mode_week") }
        static var modeMonth: String    { L10n.s("calendar.mode_month") }
    }
}

// MARK: - Enum Display Name Extensions

extension ContentType {
    var displayName: String {
        switch self {
        case .post:        return NSLocalizedString("content_type.post", comment: "")
        case .carousel:    return NSLocalizedString("content_type.carousel", comment: "")
        case .reels:       return NSLocalizedString("content_type.reels", comment: "")
        case .stories:     return NSLocalizedString("content_type.stories", comment: "")
        case .contentPack: return NSLocalizedString("content_type.content_pack", comment: "")
        }
    }
}

extension ContentStatus {
    var displayName: String {
        switch self {
        case .draft:     return NSLocalizedString("content_status.draft", comment: "")
        case .ready:     return NSLocalizedString("content_status.ready", comment: "")
        case .scheduled: return NSLocalizedString("content_status.scheduled", comment: "")
        case .published: return NSLocalizedString("content_status.published", comment: "")
        }
    }
}

extension ContentTone {
    var displayName: String {
        switch self {
        case .educational: return NSLocalizedString("content_tone.educational", comment: "")
        case .personal:    return NSLocalizedString("content_tone.personal", comment: "")
        case .sales:       return NSLocalizedString("content_tone.sales", comment: "")
        case .authority:   return NSLocalizedString("content_tone.authority", comment: "")
        case .engagement:  return NSLocalizedString("content_tone.engagement", comment: "")
        }
    }
}

extension ContentGoal {
    var displayName: String {
        switch self {
        case .awareness:  return NSLocalizedString("content_goal.awareness", comment: "")
        case .trust:      return NSLocalizedString("content_goal.trust", comment: "")
        case .sales:      return NSLocalizedString("content_goal.sales", comment: "")
        case .engagement: return NSLocalizedString("content_goal.engagement", comment: "")
        case .education:  return NSLocalizedString("content_goal.education", comment: "")
        }
    }
}

extension UserType {
    var displayName: String {
        switch self {
        case .creator:       return NSLocalizedString("user_type.creator", comment: "")
        case .expert:        return NSLocalizedString("user_type.expert", comment: "")
        case .smallBusiness: return NSLocalizedString("user_type.small_business", comment: "")
        case .agency:        return NSLocalizedString("user_type.agency", comment: "")
        }
    }
}

extension VisualMood {
    var displayName: String {
        switch self {
        case .minimal:   return NSLocalizedString("visual_mood.minimal", comment: "")
        case .bold:      return NSLocalizedString("visual_mood.bold", comment: "")
        case .editorial: return NSLocalizedString("visual_mood.editorial", comment: "")
        case .soft:      return NSLocalizedString("visual_mood.soft", comment: "")
        case .premium:   return NSLocalizedString("visual_mood.premium", comment: "")
        }
    }
}

extension CalendarViewMode {
    var displayName: String {
        switch self {
        case .week:  return NSLocalizedString("calendar.mode_week", comment: "")
        case .month: return NSLocalizedString("calendar.mode_month", comment: "")
        }
    }
}
