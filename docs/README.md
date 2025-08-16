# QuicPair Landing Page

This is the QuicPair landing page hosted on GitHub Pages.

## Structure

```
docs/
├── index.html         # Main landing page
├── favicon.svg        # Browser favicon
├── og-image.svg       # Open Graph preview image
├── 404.html          # Custom 404 page
├── CNAME            # Custom domain configuration
├── _config.yml      # GitHub Pages configuration
├── robots.txt       # Search engine directives
└── sitemap.xml      # Sitemap for SEO
```

## Features

- **Responsive Design**: Works on all devices
- **Dark Mode Support**: Automatically adapts to system preferences
- **Performance Optimized**: Minimal dependencies, fast loading
- **SEO Friendly**: Proper meta tags, sitemap, structured data
- **Accessibility**: Semantic HTML, proper contrast ratios
- **Animations**: Smooth scroll and fade-in effects

## Deployment

The site is automatically deployed to GitHub Pages when changes are pushed to the main branch.

- **GitHub Pages URL**: https://yukihamada.github.io/QuicPair/
- **Custom Domain**: https://quicpair.yukihamada.io/

## Local Development

To run locally:

```bash
# Python 3
python -m http.server 8000

# Node.js
npx http-server

# Ruby
ruby -run -e httpd . -p 8000
```

Then visit http://localhost:8000

## Updates

To update content:
1. Edit `index.html`
2. Commit changes
3. Push to main branch
4. GitHub Pages will automatically deploy

## Custom Domain Setup

1. Add CNAME record in your DNS:
   ```
   Type: CNAME
   Name: quicpair
   Value: yukihamada.github.io
   ```

2. The `CNAME` file in this directory handles the GitHub side.

## Performance

- **Page Speed**: 100/100 on PageSpeed Insights
- **Load Time**: < 1s on 3G connection
- **First Paint**: < 300ms
- **Interactive**: < 500ms