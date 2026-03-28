# Storefront Code Diffs

## 1. `src/modules/home/components/hero/index.tsx` — Background Image + Carousel + Mobile Arrow Hiding

**Original (35 lines):**

```tsx
import { Github } from "@medusajs/icons"
import { Button, Heading } from "@medusajs/ui"

const Hero = () => {
  return (
    <div className="h-[75vh] w-full border-b border-ui-border-base relative bg-ui-bg-subtle">
      <div className="absolute inset-0 z-10 flex flex-col justify-center items-center text-center small:p-32 gap-6">
        <span>
          <Heading
            level="h1"
            className="text-3xl leading-10 text-ui-fg-base font-normal"
          >
            Ecommerce Starter Template
          </Heading>
          <Heading
            level="h2"
            className="text-3xl leading-10 text-ui-fg-subtle font-normal"
          >
            Powered by Medusa and Next.js
          </Heading>
        </span>
        <a
          href="https://github.com/medusajs/nextjs-starter-medusa"
          target="_blank"
        >
          <Button variant="secondary">
            View on GitHub
            <Github />
          </Button>
        </a>
      </div>
    </div>
  )
}

export default Hero
```

**New (130 lines):**

```tsx
"use client"

import { useCallback, useEffect, useState } from "react"
import { Button, Heading } from "@medusajs/ui"
import { ArrowRightMini } from "@medusajs/icons"

const slides = [
  {
    image: "/hero-bg.jpg",
    heading: "New Season Arrivals",
    subheading: "Discover the latest trends in fashion and lifestyle.",
    ctaLabel: "Shop Now",
    ctaHref: "/store",
  },
  {
    image: "/hero-bg-2.jpg",
    heading: "Summer Collection",
    subheading: "Light styles for warm days — up to 30% off.",
    ctaLabel: "Browse Collection",
    ctaHref: "/store",
  },
  {
    image: "/hero-bg-3.jpg",
    heading: "Free Shipping",
    subheading: "On all orders over $50. Limited time offer.",
    ctaLabel: "Start Shopping",
    ctaHref: "/store",
  },
]

const INTERVAL_MS = 6000

const Hero = () => {
  const [current, setCurrent] = useState(0)
  const [paused, setPaused] = useState(false)

  const goTo = useCallback((index: number) => {
    setCurrent(index)
  }, [])

  const next = useCallback(() => {
    setCurrent((prev) => (prev + 1) % slides.length)
  }, [])

  const prev = useCallback(() => {
    setCurrent((prev) => (prev - 1 + slides.length) % slides.length)
  }, [])

  useEffect(() => {
    if (paused) return
    const id = setInterval(next, INTERVAL_MS)
    return () => clearInterval(id)
  }, [paused, next])

  return (
    <div
      className="h-[75vh] w-full border-b border-ui-border-base relative overflow-hidden"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
    >
      {slides.map((slide, index) => (
        <div
          key={index}
          className="absolute inset-0 bg-cover bg-center transition-opacity duration-700 ease-in-out"
          style={{
            backgroundImage: `url('${slide.image}')`,
            opacity: index === current ? 1 : 0,
            zIndex: index === current ? 1 : 0,
          }}
        >
          <div className="absolute inset-0 bg-black/40" />
          <div className="absolute inset-0 flex flex-col justify-center items-center text-center small:p-32 gap-6 z-10">
            <span>
              <Heading
                level="h1"
                className="text-4xl leading-10 text-white font-semibold"
              >
                {slide.heading}
              </Heading>
              <Heading
                level="h2"
                className="text-lg leading-8 text-white/80 font-normal mt-2"
              >
                {slide.subheading}
              </Heading>
            </span>
            <a href={slide.ctaHref}>
              <Button variant="secondary" className="bg-white text-black hover:bg-white/90">
                {slide.ctaLabel}
                <ArrowRightMini />
              </Button>
            </a>
          </div>
        </div>
      ))}

      {/* Previous / Next arrows — hidden on mobile */}
      <button
        onClick={prev}
        className="hidden small:flex absolute left-4 top-1/2 -translate-y-1/2 z-20 bg-white/20 hover:bg-white/40 backdrop-blur-sm text-white rounded-full w-10 h-10 items-center justify-center transition-colors"
        aria-label="Previous slide"
      >
        ‹
      </button>
      <button
        onClick={next}
        className="hidden small:flex absolute right-4 top-1/2 -translate-y-1/2 z-20 bg-white/20 hover:bg-white/40 backdrop-blur-sm text-white rounded-full w-10 h-10 items-center justify-center transition-colors"
        aria-label="Next slide"
      >
        ›
      </button>

      {/* Navigation dots */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-20 flex gap-2">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => goTo(index)}
            className={`w-2.5 h-2.5 rounded-full transition-colors ${
              index === current ? "bg-white" : "bg-white/40"
            }`}
            aria-label={`Go to slide ${index + 1}`}
          />
        ))}
      </div>
    </div>
  )
}

export default Hero
```

---

## 2. `src/app/[countryCode]/(main)/page.tsx` — Add Featured Categories

**Original (41 lines):**

```tsx
import { Metadata } from "next"

import FeaturedProducts from "@modules/home/components/featured-products"
import Hero from "@modules/home/components/hero"
import { listCollections } from "@lib/data/collections"
import { getRegion } from "@lib/data/regions"

export const metadata: Metadata = {
  title: "Medusa Next.js Starter Template",
  description:
    "A performant frontend ecommerce starter template with Next.js 15 and Medusa.",
}

export default async function Home(props: {
  params: Promise<{ countryCode: string }>
}) {
  const params = await props.params

  const { countryCode } = params

  const region = await getRegion(countryCode)

  const { collections } = await listCollections({
    fields: "id, handle, title",
  })

  if (!collections || !region) {
    return null
  }

  return (
    <>
      <Hero />
      <div className="py-12">
        <ul className="flex flex-col gap-x-6">
          <FeaturedProducts collections={collections} region={region} />
        </ul>
      </div>
    </>
  )
}
```

**New (54 lines):**

```diff
  import { Metadata } from "next"

  import FeaturedProducts from "@modules/home/components/featured-products"
+ import FeaturedCategories from "@modules/home/components/featured-categories"
  import Hero from "@modules/home/components/hero"
  import { listCollections } from "@lib/data/collections"
+ import { listCategories } from "@lib/data/categories"
  import { getRegion } from "@lib/data/regions"

  export const metadata: Metadata = {
    title: "Medusa Next.js Starter Template",
    description:
      "A performant frontend ecommerce starter template with Next.js 15 and Medusa.",
  }

  export default async function Home(props: {
    params: Promise<{ countryCode: string }>
  }) {
    const params = await props.params

    const { countryCode } = params

    const region = await getRegion(countryCode)

    const { collections } = await listCollections({
      fields: "id, handle, title",
    })

+   const categories = await listCategories({
+     limit: 4,
+   })

    if (!collections || !region) {
      return null
    }

    return (
      <>
        <Hero />
+       {categories && categories.length > 0 && (
+         <div className="content-container">
+           <ul className="flex flex-col gap-x-6">
+             <FeaturedCategories categories={categories} region={region} />
+           </ul>
+         </div>
+       )}
        <div className="py-12">
          <ul className="flex flex-col gap-x-6">
            <FeaturedProducts collections={collections} region={region} />
          </ul>
        </div>
      </>
    )
  }
```

---

## 3. `src/modules/home/components/featured-categories/index.tsx` — New File

```tsx
import { HttpTypes } from "@medusajs/types"
import CategoryRail from "@modules/home/components/featured-categories/category-rail"

export default async function FeaturedCategories({
  categories,
  region,
}: {
  categories: HttpTypes.StoreProductCategory[]
  region: HttpTypes.StoreRegion
}) {
  return categories.map((category) => (
    <li key={category.id}>
      <CategoryRail category={category} region={region} />
    </li>
  ))
}
```

---

## 4. `src/modules/home/components/featured-categories/category-rail/index.tsx` — New File

```tsx
import { listProducts } from "@lib/data/products"
import { HttpTypes } from "@medusajs/types"
import { Text } from "@medusajs/ui"

import InteractiveLink from "@modules/common/components/interactive-link"
import ProductPreview from "@modules/products/components/product-preview"

export default async function CategoryRail({
  category,
  region,
}: {
  category: HttpTypes.StoreProductCategory
  region: HttpTypes.StoreRegion
}) {
  const {
    response: { products },
  } = await listProducts({
    regionId: region.id,
    queryParams: {
      category_id: [category.id],
      fields: "*variants.calculated_price",
      limit: 4,
    },
  })

  if (!products || products.length === 0) {
    return null
  }

  return (
    <div className="py-12 small:py-24">
      <div className="flex justify-between mb-8">
        <Text className="txt-xlarge">{category.name}</Text>
        <InteractiveLink href={`/categories/${category.handle}`}>
          View all
        </InteractiveLink>
      </div>
      <ul className="grid grid-cols-2 small:grid-cols-4 gap-x-6 gap-y-24 small:gap-y-36">
        {products.map((product) => (
          <li key={product.id}>
            <ProductPreview product={product} region={region} isFeatured />
          </li>
        ))}
      </ul>
    </div>
  )
}
```
