FROM node:lts-alpine as builder

ARG BRANCH=main
ARG COMMIT=33ff182

WORKDIR /build

RUN apk add --no-cache git python3 make g++
RUN git clone --branch ${BRANCH} --recurse-submodules https://github.com/Gurkengewuerz/nitro.git .
RUN git checkout $COMMIT
RUN npm install --force
RUN npm install --save-dev nx
RUN npx nx build frontend

# Safari/iOS landscape fixes: anchor the html/body 100% height chain that
# Safari's viewport model needs (Chrome tolerates the missing html{height}
# rule, Safari does not), add dynamic-viewport-height + safe-area-inset
# fallbacks for notched iPhones, and register the missing
# apple-mobile-web-app-capable meta tag alongside its existing siblings.
RUN cat <<'EOF' > /build/dist/apps/frontend/safari-fix.css
html {
    height: 100%;
    height: -webkit-fill-available;
}
body {
    min-height: 100vh;
    min-height: -webkit-fill-available;
    min-height: 100dvh;
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
}
#root {
    min-height: 100dvh;
}
EOF
RUN sed -i \
    -e 's#<meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1" />#<meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, viewport-fit=cover" />#' \
    -e 's#<meta name="mobile-web-app-capable" content="yes">#<meta name="mobile-web-app-capable" content="yes">\n    <meta name="apple-mobile-web-app-capable" content="yes" />#' \
    -e 's#</head>#    <link rel="stylesheet" href="/safari-fix.css">\n  </head>#' \
    /build/dist/apps/frontend/index.html



FROM nginx:alpine

COPY --from=builder /build/dist/apps/frontend/ /usr/share/nginx/html/
