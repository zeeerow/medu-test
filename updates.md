# Storefront Updates

## 1. Hero Section with Background Image

**File:** `src/modules/home/components/hero/index.tsx`

The existing hero component was a static, centered text block with a GitHub link. It was updated to support a background image with a dark overlay for text readability.

### Changes

- Added `bg-cover bg-center` Tailwind classes to the outer container for background image sizing
- Added an inline `backgroundImage` style pointing to `/hero-bg.jpg` in the `public/` directory
- Added a semi-transparent dark overlay (`bg-black/40`) between the background and the content layer
- Changed text colors from theme variables (`text-ui-fg-base`, `text-ui-fg-subtle`) to white (`text-white`, `text-white/80`) so contrast works against any background image

### Required Assets

Place background images in `public/`:
- `hero-bg.jpg`

---

## 2. Hero Carousel

**File:** `src/modules/home/components/hero/index.tsx`

The hero was converted from a static component to an interactive carousel with auto-advancing slides, navigation arrows, and dot indicators.

### Changes

- Converted to a `"use client"` component since it requires React state and effects
- Defined a `slides` array with 3 slides, each containing `image`, `heading`, `subheading`, `ctaLabel`, and `ctaHref`
- Added `current` state to track the active slide index
- Added `paused` state to pause auto-advance on hover via `onMouseEnter`/`onMouseLeave`
- Implemented auto-advance with `useEffect` + `setInterval` at a 6-second interval (`INTERVAL_MS = 6000`)
- Added fade transitions between slides using CSS `transition-opacity duration-700`
- Each slide has a "Shop Now" style CTA button using the `@medusajs/ui` `Button` component with an `ArrowRightMini` icon
- Added previous/next arrow buttons positioned on the left and right edges
- Added navigation dots at the bottom center, with the active dot highlighted

### Required Assets

Place these images in `public/`:
- `hero-bg.jpg` (slide 1)
- `hero-bg-2.jpg` (slide 2)
- `hero-bg-3.jpg` (slide 3)

---

## 3. Hide Carousel Arrows on Mobile

**File:** `src/modules/home/components/hero/index.tsx`

The prev/next arrow buttons are hidden on screens below the `small` breakpoint (1024px, defined in `tailwind.config.js`).

### Changes

- Changed the arrow button className from `flex` to `hidden small:flex`
- Below 1024px, users navigate via the dot indicators only
- Above 1024px, both arrows and dots are visible

---

## 4. Featured Categories Section

### New File: `src/modules/home/components/featured-categories/index.tsx`

A server component that maps an array of `StoreProductCategory` objects to individual `CategoryRail` components. Follows the same pattern as the existing `FeaturedProducts` component.

### New File: `src/modules/home/components/featured-categories/category-rail/index.tsx`

A server component that fetches and displays products for a single category.

### Behavior

- Fetches up to 4 products per category using `listProducts` with `category_id` filter
- Uses the existing `ProductPreview` component to render each product card
- Displays the category name as a heading with a "View all" `InteractiveLink` pointing to `/categories/<handle>`
- Renders products in a responsive grid: 2 columns on mobile, 4 columns on desktop (`grid-cols-2 small:grid-cols-4`)
- Returns `null` if the category has no products, skipping that section entirely

---

## 5. Homepage Integration

**File:** `src/app/[countryCode]/(main)/page.tsx`

The main page was updated to fetch categories and render the new featured categories section between the hero carousel and the existing featured products (collections) section.

### Changes

- Added import for `FeaturedCategories` component
- Added import for `listCategories` from `@lib/data/categories`
- Fetches up to 4 categories with `listCategories({ limit: 4 })`
- Renders `FeaturedCategories` between `<Hero />` and the existing `FeaturedProducts` section
- Categories section is conditionally rendered — only displays if categories exist and have products
- Wrapped the categories section in `content-container` for consistent page-width alignment

### Page Layout Order

1. Hero carousel
2. Featured categories (products from each category)
3. Featured products by collection (existing)
