# Kadro

Kadro is a premium native iOS app that helps creators, experts, and small businesses turn raw ideas into polished social content.

It is designed as a guided mobile content studio, not as a generic AI chatbot. The product focuses on helping users go from a rough thought, voice note, or short prompt to a ready Instagram post, carousel, story sequence, or TikTok/Reels script with as little friction as possible.

This README is the single source of truth for product direction, design taste, UX principles, color usage, feature scope, and implementation intent. It should be used as the default reference file before making product, design, or engineering decisions.

---

## 1. Product summary

### One-line definition
Kadro is an AI-powered native iPhone content studio that turns ideas into publish-ready social content.

### What Kadro solves
Many users know what they want to say, but they struggle with:
- starting from a blank page
- structuring content clearly
- turning one idea into multiple content formats
- making carousels look polished
- keeping a consistent tone of voice
- publishing regularly without a full designer or SMM workflow

Kadro reduces this friction by guiding the user through a simple flow:
1. capture an idea
2. choose a format
3. generate structured content
4. refine quickly
5. save, organize, or schedule

### Core product promise
A user should be able to open Kadro, give it a rough idea, and leave with something useful and concrete in just a few minutes.

---

## 2. Product vision

Kadro should feel like a product worthy of:
- Editor's Choice
- App of the Week
- premium App Store featuring
- strong word-of-mouth among creators

This means the app must feel:
- modern
- cool
- minimal
- premium
- highly legible
- friendly to beginners
- visually disciplined
- fast and calm, not noisy

Kadro should never feel like a generic AI app with an empty chat box and glowing gradients.

---

## 3. Product positioning

### What Kadro is
- a native iOS content companion
- an AI-assisted social content workflow tool
- a content operating system for creators
- a structured post and carousel generator
- a brand-aware content helper

### What Kadro is not
- not a generic chatbot
- not a desktop Canva replacement on mobile
- not an enterprise analytics dashboard
- not a bloated agency suite
- not a vague "AI writer for everything"

### Main value statement
Kadro helps users turn thoughts into ready content with speed, structure, and taste.

---

## 4. Target audience

### Primary users
- solo creators
- coaches
- consultants
- educators
- founders building a personal brand
- small business owners

### Secondary users
- SMM freelancers
- content managers
- creator assistants

### User reality
Most users are not designers and are not naturally good at structuring content. The app must simplify the process and guide them clearly.

---

## 5. Core jobs to be done

Users hire Kadro to:
- quickly capture ideas when inspiration appears
- create a post from a raw thought
- turn one idea into multiple content types
- make carousels without manual design work
- keep a consistent voice and style
- produce content faster
- maintain a publishing rhythm with less effort

---

## 6. UX principles

These principles should guide all design and implementation decisions.

### 6.1 Workflow-first, not chat-first
AI supports the workflow, but the product should be organized around steps and outcomes, not around endless conversation.

### 6.2 One primary action per screen
Each important screen should make the next action obvious.

### 6.3 Structured output, never text walls
Generated content should be split into clearly labeled sections such as:
- hook
- main text
- CTA
- slide titles
- script beats
- caption

### 6.4 Preview matters
Users should see previews as often as possible, especially for carousel content.

### 6.5 Control without overload
The app should provide useful control while hiding unnecessary complexity.

### 6.6 Human language only
Avoid vague product jargon. Use labels such as:
- Create carousel
- Make hook stronger
- Turn into TikTok
- Shorten text

### 6.7 Beginner clarity first
A first-time user should understand where to start in under 10 seconds.

---

## 7. Main navigation

Kadro uses a 5-tab structure on iPhone:

1. Home
2. Create
3. Content
4. Calendar
5. Brand

This is the main information architecture and should remain stable unless there is a very strong reason to change it.

---

## 8. Screen overview

### 8.1 Home
Purpose:
- reduce anxiety
- show where to start
- show unfinished work
- suggest useful next actions

Contains:
- greeting header
- hero card with Create Content CTA
- quick action cards
- continue working section
- AI idea suggestions
- smart planning hints

### 8.2 Create
Purpose:
- guide the user through content creation

Flow:
- choose input source
- enter idea
- choose output type
- generate
- review and refine

### 8.3 Generated Result
Purpose:
- present output in a structured, useful format

Possible outputs:
- Instagram post
- carousel
- TikTok/Reels script
- story sequence
- full content pack

### 8.4 Post Editor
Purpose:
- let users refine post copy quickly

Must support:
- editing hook, body, CTA
- AI rewrite shortcuts
- changing tone and length
- turning content into another format

### 8.5 Carousel Editor
Purpose:
- edit carousel slide by slide with mobile-friendly simplicity

Must support:
- current slide preview
- slide thumbnails
- text editing
- layout presets
- style presets
- regenerate slide

### 8.6 Content Library
Purpose:
- organize created content clearly

Must include:
- Drafts
- Ready
- Scheduled
- Published

### 8.7 Calendar
Purpose:
- make publishing rhythm visible
- reveal empty days
- allow lightweight planning

Default mode should be Week view.

### 8.8 Brand
Purpose:
- teach Kadro how the user writes and what visual mood they prefer

Must include:
- basics
- tone
- writing rules
- visual preferences
- best examples

### 8.9 Onboarding
Purpose:
- explain value quickly
- collect only essential setup
- lead directly into first successful content generation

### 8.10 Settings
Purpose:
- account settings
- subscription
- notifications
- support
- connected services

---

## 9. Core feature set

### 9.1 Idea capture
Users can start from:
- a topic
- bullet points
- a voice note
- pasted text
- a link
- an old post
- best past content

### 9.2 AI generation
From one idea, Kadro should be able to produce:
- Instagram post
- carousel outline
- TikTok/Reels script
- story sequence
- CTA options
- multiple tone and length variations

### 9.3 Brand memory
Kadro should store and reuse:
- niche
- audience
- tone
- words to use
- words to avoid
- CTA preferences
- visual style preferences
- content references

### 9.4 Carousel builder
Kadro should support:
- slide-by-slide editing
- strong first slide generation
- concise text fitting
- preset styles
- preset layouts
- quick refinement

### 9.5 Content library
Users should be able to:
- browse
- search
- filter
- duplicate
- reschedule
- reopen drafts

### 9.6 Calendar and planning
Users should be able to:
- see upcoming content
- identify gaps
- reschedule content
- add content to a day quickly

### 9.7 Monetization
The app should support a premium tier with:
- more generations
- more variants
- advanced brand memory
- advanced carousel tools
- scheduling features

---

## 10. Color system

The chosen color direction is:

**Charcoal + Lime**

This palette is intentionally different from the common blue-purple gradient style used by many AI apps. It should make Kadro feel more premium, editorial, and memorable.

### 10.1 Core colors

#### Charcoal
Use for:
- primary text
- dark UI emphasis
- icons
- important contrast surfaces

Hex:
`#171717`

#### Soft Ivory
Use for:
- main background
- large page surfaces
- warm neutral canvas

Hex:
`#F5F1E8`

#### Muted Lime
Use for:
- primary CTA
- active states
- progress highlights
- selected chips
- emphasis moments

Hex:
`#C7D92C`

#### Warm Gray
Use for:
- secondary text
- metadata
- quieter labels

Hex:
`#8E8A83`

#### Sand
Use for:
- dividers
- subtle borders
- secondary surfaces
- inactive controls

Hex:
`#DDD6C8`

#### Soft White
Use for:
- cards
- elevated surfaces
- modal or sheet backgrounds when needed

Hex:
`#FFFDF8`

### 10.2 Color usage rules
- 80% neutral base
- 15% supporting neutrals
- 5% accent color
- lime should be used with restraint
- avoid oversaturation
- avoid gradient-based branding
- avoid blue and purple accents

### 10.3 Product feeling from color
The color system should make Kadro feel:
- modern
- sharp
- calm
- premium
- creative without becoming playful or childish

---

## 11. Visual style

### Desired design taste
The app should feel like a blend of:
- premium productivity app
- modern creator tool
- editorial minimalism
- calm native iOS design

### Must feel
- airy
- clean
- carefully spaced
- visually coherent
- not crowded
- not gamified
- not gimmicky

### Avoid
- gradients
- neon overload
- crypto-looking dark UI
- excessive glow
- busy AI sparkles everywhere
- generic SaaS illustrations

### UI guidance
- large titles
- clear hierarchy
- rounded corners, but not exaggerated
- soft cards
- high legibility
- restrained iconography
- motion that supports structure

---

## 12. Typography guidance

Typography should feel:
- editorial
- confident
- readable
- modern
- simple

Rules:
- use strong hierarchy
- avoid too many font weights
- prioritize scanability
- use larger titles and clean body sizes
- make section labels clear and human-readable

---

## 13. Motion guidance

To feel premium and feature-worthy, motion should be:
- subtle
- smooth
- fast
- intentional
- calm

Good motion opportunities:
- transitioning between creation steps
- selecting cards
- showing generated results
- switching carousel slides
- presenting bottom sheets
- showing save/schedule success states

Avoid:
- flashy transitions
- overly bouncy behavior
- decorative motion with no purpose

---

## 14. Brand direction

### App name
**Kadro**

### Brand associations
The name should suggest:
- a frame
- a content block
- a polished piece of media
- visual structure
- modern creation

### Icon direction
The icon should be:
- simple
- high-contrast
- memorable at small size
- distinctive in the App Store

Avoid:
- robot faces
- generic sparkle icons
- soft gradient blobs
- overcomplicated linework

---

## 15. Product tone and copy style

The app should speak in a way that feels:
- clear
- calm
- encouraging
- confident
- concise

Copy should never feel:
- robotic
- overly salesy
- technical
- cluttered
- vague

### Good examples
- Create content
- Turn into carousel
- Make hook stronger
- Shorten text
- Try another style
- Schedule for Wednesday

### Avoid examples
- Generate asset
- Optimize content output
- Repurpose unit
- Narrative enhancement
- Social publish configuration

---

## 16. Recommended tech direction

This section is guidance for implementation.

### Platform
Native iOS first.

### Recommended stack
- SwiftUI
- async/await
- modular architecture
- local persistence for drafts
- design token system
- analytics hooks
- remote config if needed

### Why native
Native iOS is important because Kadro depends on:
- premium motion
- high-quality interaction
- fast capture
- voice note input
- polished mobile editing
- perceived product quality

---

## 17. MVP scope

### Included in MVP
- onboarding
- Home tab
- Create flow
- Instagram post generation
- carousel generation
- TikTok/Reels script generation
- basic post editor
- basic carousel editor
- content library
- basic calendar
- brand settings
- paywall

### Not included in first release
- advanced analytics
- team collaboration
- deep social integrations
- enterprise permissions
- desktop-grade design editor
- social inbox
- complex automation workflows

---

## 18. Success criteria

The app is successful if a first-time user can:
1. understand the app quickly
2. start creating without confusion
3. generate useful content from one idea
4. refine the result without friction
5. save or schedule something meaningful
6. feel the app is premium and different from generic AI tools

---

## 19. Product constraints

These constraints are important and intentional.

### Do not turn Kadro into:
- a cluttered social media dashboard
- a desktop editor squeezed into mobile
- a general-purpose chat app
- a feature list with no clear product shape

### Protect these qualities:
- simplicity
- focus
- speed
- taste
- structure
- visual identity
- beginner friendliness

---

## 20. Reference summary for codex

When making decisions, assume the following are always true unless explicitly changed:

- Product name: **Kadro**
- Platform focus: **native iOS**
- Navigation: **Home / Create / Content / Calendar / Brand**
- Design target: **Editor’s Choice / App of the Week quality**
- Main palette: **Charcoal + Lime**
- Avoided colors: **purple, blue, gradients**
- Product style: **minimal, premium, modern, calm**
- UX approach: **workflow-first, not chat-first**
- Core job: **turn ideas into publish-ready social content**
- Primary users: **creators, experts, small businesses**
- Main content types: **posts, carousels, story sequences, TikTok/Reels scripts**
- Editing approach: **simple, guided, mobile-friendly**
- Brand memory: **required**
- Carousel experience: **preset-based and slide-focused**
- Week view is default for Calendar
- Lime is an accent, not the whole interface

---

## 21. Final quality bar

Every part of Kadro should support this feeling:

> A user opens the app, immediately understands what to do, creates something polished in minutes, and feels that the app is smarter, cleaner, and more refined than typical AI tools.

This README should be treated as the project's main product and design reference unless a newer version explicitly replaces it.
