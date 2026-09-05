# Stage 1: Composer dependencies
FROM php:8.5-cli-alpine AS composer-builder

ARG COMMIT=f77e2b6

WORKDIR /app

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    git \
    zip \
    unzip \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    linux-headers

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    sockets \
    intl \
    pdo_mysql \
    zip \
    gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Clone the repository
RUN git config --global --add safe.directory /app
RUN git clone --recurse-submodules https://github.com/ObjectRetros/atomcms.git .
RUN git checkout $COMMIT

# Upstream bug (re-verified against the current codebase after the 53ea66d -> f77e2b6
# update, since upstream rewrote the whole badge subsystem in between): UserBadge (a
# user's actual earned badges, shown in Housekeeping > Users > Badges) still doesn't
# implement the HasBadge interface, unlike every other model HabboBadgeColumn expects.
# HabboBadgeColumn::getBadgePath()/getBadgeName() silently return '' for any record that
# isn't a HasBadge instance, so every user's badge list renders as broken images.
# (The old shop-package and room-guild-badge variants of this bug are gone: shop packages
# now use a direct image upload (Storage::url($package->image)) instead of a badge code,
# and the website no longer has a room/guild detail page at all.)
COPY <<'EOF' /tmp/fix_user_badge.php
<?php
$path = "/app/app/Models/Game/Player/UserBadge.php";
$content = file_get_contents($path);

$old1 = "use Illuminate\Database\Eloquent\Relations\BelongsTo;";
$new1 = "use App\Models\Compositions\HasBadge;\nuse Illuminate\Database\Eloquent\Relations\BelongsTo;";
if (strpos($content, $old1) === false) {
    fwrite(STDERR, "fix_user_badge: import line not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old1, $new1, $content);

$old2 = "class UserBadge extends Model\n{";
$new2 = "class UserBadge extends Model implements HasBadge\n{";
if (strpos($content, $old2) === false) {
    fwrite(STDERR, "fix_user_badge: class declaration not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old2, $new2, $content);

$old3 = "    public function user(): BelongsTo\n    {\n        return \$this->belongsTo(User::class, 'user_id');\n    }\n}";
$new3 = "    public function user(): BelongsTo\n    {\n        return \$this->belongsTo(User::class, 'user_id');\n    }\n\n    public function getBadgePath(): string\n    {\n        return sprintf('%s%s.gif', setting('badges_path'), \$this->getBadgeName());\n    }\n\n    public function getBadgeName(): string\n    {\n        return \$this->badge_code ?: '';\n    }\n}";
if (strpos($content, $old3) === false) {
    fwrite(STDERR, "fix_user_badge: closing brace pattern not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($old3, $new3, $content);

file_put_contents($path, $content);
echo "fix_user_badge: patched $path\n";
EOF
RUN php /tmp/fix_user_badge.php && rm /tmp/fix_user_badge.php

# Upstream bug: the homepage ('/') and the no-op '/login' redirect are grouped under the
# same throttle:15,1 limiter as the brute-force-sensitive auth routes (register, password
# reset). 15 requests/min is meant to slow down credential-stuffing on those POST routes,
# but it also caps plain homepage visits, so a handful of page loads/reloads in a minute
# (mobile Safari retries, multiple tabs, etc.) return 429 on the homepage itself.
COPY <<'EOF' /tmp/fix_homepage_throttle.php
<?php
$path = "/app/routes/web.php";
$content = file_get_contents($path);

$old = <<<'OLD'
    Route::middleware(['guest', 'throttle:15,1'])->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/login', static fn () => to_route('welcome'))->name('login');
        Route::get('/', HomeController::class)->name('welcome');

        Route::get('/register', [RegisteredUserController::class, 'create']);
OLD;

$new = <<<'NEW'
    Route::middleware('guest')->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/login', static fn () => to_route('welcome'))->name('login');
        Route::get('/', HomeController::class)->name('welcome');
    });

    Route::middleware(['guest', 'throttle:15,1'])->withoutMiddleware('force.staff.2fa')->group(function () {
        Route::get('/register', [RegisteredUserController::class, 'create']);
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "fix_homepage_throttle: pattern not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "fix_homepage_throttle: patched $path\n";
EOF
RUN php /tmp/fix_homepage_throttle.php && rm /tmp/fix_homepage_throttle.php

# Upstream bug: User::$hidden includes 'mail' (so it's stripped from API/JSON output),
# but Filament's edit form fills its fields from that same hidden-aware serialization,
# so the "Change Email" field always loads blank for every user. Since the field is
# required(), saving any user (e.g. just to adjust credits) fails validation with
# "The email field is required" unless the admin notices and retypes the address.
COPY <<'EOF' /tmp/fix_user_email_form.php
<?php
$path = "/app/app/Filament/Resources/User/Users/UserResource.php";
$content = file_get_contents($path);

$old = <<<'OLD'
                                        TextInput::make('mail')
                                            ->label(__('filament::resources.inputs.email'))
                                            ->email()
                                            ->required(),
OLD;

$new = <<<'NEW'
                                        TextInput::make('mail')
                                            ->label(__('filament::resources.inputs.email'))
                                            ->email()
                                            ->required()
                                            ->afterStateHydrated(function (TextInput $component, ?User $record) {
                                                if ($record) {
                                                    $component->state($record->getRawOriginal('mail'));
                                                }
                                            }),
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "fix_user_email_form: pattern not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "fix_user_email_form: patched $path\n";
EOF
RUN php /tmp/fix_user_email_form.php && rm /tmp/fix_user_email_form.php

# Upstream bug: registration sets starting credits via `setting('start_credits') ?: 1000`.
# PHP's `?:` (Elvis) operator treats "0" as falsy just like null/empty, so an admin who
# deliberately configures start_credits=0 (new members should start with nothing) still
# gets 1000 credits on every registration -- the explicit zero is silently overridden.
# Swap to `??` (null coalescing), which only falls back on an actually-unset setting and
# respects a real zero.
COPY <<'EOF' /tmp/fix_start_credits_zero.php
<?php
$path = "/app/app/Actions/Fortify/CreateNewUser.php";
$content = file_get_contents($path);

$old = "'credits' => setting('start_credits') ?: 1000,";
$new = "'credits' => setting('start_credits') ?? 1000,";

if (strpos($content, $old) === false) {
    fwrite(STDERR, "fix_start_credits_zero: pattern not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "fix_start_credits_zero: patched $path\n";
EOF
RUN php /tmp/fix_start_credits_zero.php && rm /tmp/fix_start_credits_zero.php

# New feature: Terms of Service & Privacy Policy pages. Upstream AtomCMS has no Terms
# of Service or Privacy Policy route/controller/view at all -- add a minimal, clearly
# placeholder pair of legal pages plus footer links, following the same page-building
# convention as the existing Rules & Regulations page.
COPY <<'EOF' /app/app/Http/Controllers/Help/WebsiteTermsController.php
<?php

namespace App\Http\Controllers\Help;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

class WebsiteTermsController extends Controller
{
    public function __invoke(): View
    {
        return view('terms');
    }
}
EOF

COPY <<'EOF' /app/app/Http/Controllers/Help/WebsitePrivacyController.php
<?php

namespace App\Http\Controllers\Help;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

class WebsitePrivacyController extends Controller
{
    public function __invoke(): View
    {
        return view('privacy');
    }
}
EOF

# Accepts a video file upload for the rank-7 "set a custom video" furniture feature.
# Auth is a shared secret (CUSTOM_VIDEO_UPLOAD_SECRET) baked into the nitro client build
# and checked here -- the actual rank>=7 gate already happens server-side in Arcturus
# before the upload UI is ever shown, this just stops the endpoint being called directly
# by someone who never went through that UI.
COPY <<'EOF' /app/app/Http/Controllers/Api/CustomVideoUploadController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class CustomVideoUploadController extends Controller
{
    public function upload(Request $request): JsonResponse
    {
        $expected = (string) env('CUSTOM_VIDEO_UPLOAD_SECRET', '');

        if ($expected === '' || !hash_equals($expected, (string) $request->input('secret'))) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Validate by extension rather than content-sniffed MIME type -- some encoders
        // (FL Studio's own exports included) produce MP4 containers that PHP's fileinfo
        // sniffs as something other than "video/mp4" depending on which streams/atoms are
        // present, which made the stricter "mimetypes:" rule reject legitimate uploads.
        $request->validate([
            'video' => 'required|file|mimes:mp4,webm,mov,m4v|max:512000',
        ]);

        $file = $request->file('video');
        $filename = Str::uuid()->toString() . '.' . strtolower($file->getClientOriginalExtension());

        $file->storeAs('customvideos', $filename);

        return response()->json([
            'url' => rtrim(env('CUSTOM_VIDEO_ASSET_BASE_URL', ''), '/') . '/usercontent/customvideos/' . $filename,
        ]);
    }
}
EOF

COPY <<'EOF' /tmp/fix_custom_video_upload_route.php
<?php
$path = "/app/routes/api.php";
$content = file_get_contents($path);

$old = "use App\\Http\\Controllers\\Shop\\PaypalWebhookController;\nuse Illuminate\\Support\\Facades\\Route;";
$new = "use App\\Http\\Controllers\\Api\\CustomPictureUploadController;\nuse App\\Http\\Controllers\\Api\\CustomVideoUploadController;\nuse App\\Http\\Controllers\\Shop\\PaypalWebhookController;\nuse Illuminate\\Support\\Facades\\Route;";

if (strpos($content, $old) === false) {
    fwrite(STDERR, "fix_custom_video_upload_route: import anchor not found\n");
    exit(1);
}
$content = str_replace($old, $new, $content);

$old2 = "Route::post('/paypal/webhook', PaypalWebhookController::class)->name('paypal.webhook');";
$new2 = $old2 . "\nRoute::post('/custom-video/upload', [CustomVideoUploadController::class, 'upload'])->name('api.custom-video-upload')->middleware('throttle:10,1');"
    . "\nRoute::post('/custom-picture/upload', [CustomPictureUploadController::class, 'upload'])->name('api.custom-picture-upload')->middleware('throttle:10,1');";

if (strpos($content, $old2) === false) {
    fwrite(STDERR, "fix_custom_video_upload_route: route anchor not found\n");
    exit(1);
}
$content = str_replace($old2, $new2, $content);

file_put_contents($path, $content);
echo "fix_custom_video_upload_route: patched $path\n";
EOF
RUN php /tmp/fix_custom_video_upload_route.php && rm /tmp/fix_custom_video_upload_route.php

# Accepts a picture file upload for the rank-7 "set a custom picture" gallery feature.
# Same shared-secret auth as CustomVideoUploadController above (CUSTOM_VIDEO_UPLOAD_SECRET
# is reused rather than adding a second secret -- neither is a real access-control
# boundary by itself, the rank>=7 gate that matters happens server-side in Arcturus).
COPY <<'EOF' /app/app/Http/Controllers/Api/CustomPictureUploadController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class CustomPictureUploadController extends Controller
{
    public function upload(Request $request): JsonResponse
    {
        $expected = (string) env('CUSTOM_VIDEO_UPLOAD_SECRET', '');

        if ($expected === '' || !hash_equals($expected, (string) $request->input('secret'))) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $request->validate([
            'picture' => 'required|file|mimes:jpg,jpeg,png,gif|max:20480',
        ]);

        $file = $request->file('picture');
        $filename = Str::uuid()->toString() . '.' . strtolower($file->getClientOriginalExtension());

        $file->storeAs('custompictures', $filename);

        return response()->json([
            'url' => rtrim(env('CUSTOM_VIDEO_ASSET_BASE_URL', ''), '/') . '/usercontent/custompictures/' . $filename,
        ]);
    }
}
EOF

COPY <<'EOF' /app/resources/themes/dusk/views/terms.blade.php
<x-app-layout>
    @push('title', __('Terms of Service'))

    <div class="col-span-12 flex flex-col gap-y-3">
        <div class="mb-4 w-full rounded bg-yellow-600 p-4 text-white">
            {{ __('This is a placeholder Terms of Service drafted for :hotel, a non-profit, fan-made retro hotel. It is provided as a starting point and has not been reviewed by a lawyer — hotel management should review and customize it before treating it as final.', ['hotel' => setting('hotel_name')]) }}
        </div>

        <div class="flex flex-col gap-y-6">
            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>1. {{ __('Acceptance of these Terms') }}</x-slot:title>
                <x-slot:under-title>{{ __('Last updated') }}: {{ now()->format('F j, Y') }}</x-slot:under-title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __(':hotel is a free, not-for-profit, fan-made community project and is in no way affiliated with, endorsed by, or connected to Sulake Corporation Oy or the Habbo brand. By creating an account or otherwise using :hotel, you agree to these Terms of Service and to :hotel\'s Rules & Regulations, which are incorporated here by reference.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>2. {{ __('Your Account') }}</x-slot:title>

                <ul class="list-disc rounded bg-gray-100 p-3 pl-8 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    <li>{{ __('You must provide accurate information when registering and are responsible for keeping your login credentials confidential.') }}</li>
                    <li>{{ __('You are responsible for all activity that happens under your account, whether or not you personally performed it.') }}</li>
                    <li>{{ __(':hotel is intended for users old enough to consent to these Terms under the laws of their country of residence. If you are a minor, you should have a parent or guardian review this policy with you.', ['hotel' => setting('hotel_name')]) }}</li>
                    <li>{{ __('Accounts found to violate the Rules & Regulations may be warned, muted, banned, or permanently deleted at staff discretion, without prior notice.') }}</li>
                </ul>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>3. {{ __('Virtual Currency & Items') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Credits, points, furniture, badges, pets, and any other in-game currency or item on :hotel exist only within the game and have no real-world monetary value. They cannot be exchanged, sold, or redeemed for real money or goods, and :hotel makes no guarantee that any virtual item, balance, or account will continue to exist, be accessible, or retain its current form. Any real-money purchases made through the site (e.g. Habbo Club, virtual currency packages) are for access to virtual content only and are, except where required otherwise by law, non-refundable.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>4. {{ __('User Conduct') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Full behavioral rules are listed on the') }}
                    <a href="{{ route('help-center.rules.index') }}" class="font-semibold underline">{{ __('Rules & Regulations') }}</a>
                    {{ __('page. In short: no harassment, hate speech, doxxing, real-money-trading scams, cheating, exploiting bugs, or attempting to disrupt, hack, or reverse-engineer the game servers. Exploiting a bug rather than reporting it may itself be treated as a rule violation.') }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>5. {{ __('Content You Submit') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Anything you post publicly on :hotel — room names and descriptions, guild content, forum or news comments, help tickets, chat — should assume no expectation of privacy and may be moderated, logged, edited, or removed by staff at any time. You retain ownership of original content you create, but grant :hotel a license to display it as part of normal operation of the site and game.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>6. {{ __('Availability & Changes') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __(':hotel is run on a best-effort, volunteer basis. It is provided "as is" without warranty of uninterrupted uptime, data retention, or fitness for any particular purpose, and may be modified, suspended, or permanently shut down at any time without notice. These Terms may be updated periodically; continued use of :hotel after a change constitutes acceptance of the revised Terms.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>7. {{ __('Contact') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Questions about these Terms can be sent through the') }}
                    <a href="{{ route('help-center.index') }}" class="font-semibold underline">{{ __('Help Center') }}</a>.
                </div>
            </x-content.content-card>
        </div>
    </div>
</x-app-layout>
EOF

COPY <<'EOF' /app/resources/themes/dusk/views/privacy.blade.php
<x-app-layout>
    @push('title', __('Privacy Policy'))

    <div class="col-span-12 flex flex-col gap-y-3">
        <div class="mb-4 w-full rounded bg-yellow-600 p-4 text-white">
            {{ __('This is a placeholder Privacy Policy drafted for :hotel, a non-profit, fan-made retro hotel. It is provided as a starting point and has not been reviewed by a lawyer — hotel management should review and customize it (including for any applicable local data-protection law, e.g. GDPR/CCPA) before treating it as final.', ['hotel' => setting('hotel_name')]) }}
        </div>

        <div class="flex flex-col gap-y-6">
            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>1. {{ __('What We Collect') }}</x-slot:title>
                <x-slot:under-title>{{ __('Last updated') }}: {{ now()->format('F j, Y') }}</x-slot:under-title>

                <ul class="list-disc rounded bg-gray-100 p-3 pl-8 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    <li>{{ __('Account information you provide: username, email address, and password (stored hashed, never in plain text).') }}</li>
                    <li>{{ __('Gameplay data: your room designs, inventory, chat and guild activity, forum/help-ticket content, and moderation history, needed to operate the game.') }}</li>
                    <li>{{ __('Technical data: IP address and basic connection/browser metadata, logged for security, anti-abuse, and troubleshooting purposes.') }}</li>
                    <li>{{ __('Payment data: if you make a real-money purchase, payment is handled directly by our payment processor (e.g. PayPal) — :hotel does not receive or store your full card or bank details.', ['hotel' => setting('hotel_name')]) }}</li>
                </ul>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>2. {{ __('How We Use It') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('We use the data above only to: run and secure your account, operate game features (rooms, catalog, guilds, messenger), respond to help tickets, enforce the Rules & Regulations (including investigating reports and bans), and process any purchases you choose to make. We do not sell your personal data.') }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>3. {{ __('Cookies & Local Storage') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __(':hotel uses essential cookies/local storage to keep you logged in and remember basic site preferences (such as theme). These are necessary for the site to function and are not used for third-party advertising or cross-site tracking.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>4. {{ __('Who Can See It') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Your username, public room content, and public profile fields are visible to other members by nature of the game. Private data (email, IP, password hash, private messages, help tickets) is accessible only to authorized :hotel staff who need it to run the hotel, and is never shared with outside parties except where required to comply with the law.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>5. {{ __('Data Retention & Deletion') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('We keep account data for as long as your account exists, plus a reasonable period afterward for security and abuse-prevention purposes. You may request deletion of your account and associated personal data at any time through the Help Center; some minimal records may be retained where necessary for fraud prevention or legal compliance.') }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>6. {{ __("Children's Privacy") }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __(':hotel is not knowingly directed at, or intended to collect personal data from, children below the age of consent for online services in their country. If you believe a child has provided us with personal data without appropriate consent, please contact us so the account can be reviewed.', ['hotel' => setting('hotel_name')]) }}
                </div>
            </x-content.content-card>

            <x-content.content-card classes="border dark:border-gray-900">
                <x-slot:title>7. {{ __('Contact') }}</x-slot:title>

                <div class="rounded bg-gray-100 p-3 text-sm leading-relaxed dark:bg-gray-700 dark:text-gray-300">
                    {{ __('Questions about this Privacy Policy, or requests to access/delete your data, can be sent through the') }}
                    <a href="{{ route('help-center.index') }}" class="font-semibold underline">{{ __('Help Center') }}</a>.
                </div>
            </x-content.content-card>
        </div>
    </div>
</x-app-layout>
EOF

COPY <<'EOF' /tmp/add_terms_privacy_routes.php
<?php
$path = "/app/routes/web.php";
$content = file_get_contents($path);

$old1 = "use App\Http\Controllers\Help\WebsiteRulesController;";
$new1 = "use App\Http\Controllers\Help\WebsitePrivacyController;\nuse App\Http\Controllers\Help\WebsiteRulesController;\nuse App\Http\Controllers\Help\WebsiteTermsController;";
if (strpos($content, $old1) === false) {
    fwrite(STDERR, "patch_routes: use-import pattern not found\n");
    exit(1);
}
$content = str_replace($old1, $new1, $content);

$old2 = "            // Rules\n            Route::get('/rules', WebsiteRulesController::class)->name('rules.index')->withoutMiddleware('auth');";
$new2 = "            // Rules\n            Route::get('/rules', WebsiteRulesController::class)->name('rules.index')->withoutMiddleware('auth');\n\n            // Legal\n            Route::get('/terms', WebsiteTermsController::class)->name('terms.index')->withoutMiddleware('auth');\n            Route::get('/privacy', WebsitePrivacyController::class)->name('privacy.index')->withoutMiddleware('auth');";
if (strpos($content, $old2) === false) {
    fwrite(STDERR, "patch_routes: rules-route pattern not found\n");
    exit(1);
}
$content = str_replace($old2, $new2, $content);

file_put_contents($path, $content);
echo "patch_routes: patched $path\n";
EOF
RUN php /tmp/add_terms_privacy_routes.php && rm /tmp/add_terms_privacy_routes.php

COPY <<'EOF' /tmp/add_terms_privacy_footer_links.php
<?php
$path = "/app/resources/themes/dusk/views/components/footer.blade.php";
$content = file_get_contents($path);

$old = <<<'OLD'
<footer
    x-data
    x-on:click="$dispatch('open-modal', 'atom-credits')"
    class="w-full h-14 flex items-center justify-center bg-gray-900 text-gray-500 font-bold cursor-pointer transition duration-200 ease-in-out hover:text-gray-400"
>
    &copy {{ date('Y') }} {{ setting('hotel_name') }} {{ __('is a not for profit educational project & is in no way affiliated with Sulake Corporation Oy.') }}
</footer>
OLD;

$new = <<<'NEW'
<footer
    x-data
    x-on:click="$dispatch('open-modal', 'atom-credits')"
    class="w-full min-h-14 flex flex-col items-center justify-center gap-y-1 py-2 bg-gray-900 text-gray-500 font-bold cursor-pointer transition duration-200 ease-in-out hover:text-gray-400"
>
    <span>&copy {{ date('Y') }} {{ setting('hotel_name') }} {{ __('is a not for profit educational project & is in no way affiliated with Sulake Corporation Oy.') }}</span>
    <span class="text-xs font-normal">
        <a href="{{ route('help-center.terms.index') }}" x-on:click.stop class="underline hover:text-gray-300">{{ __('Terms of Service') }}</a>
        &middot;
        <a href="{{ route('help-center.privacy.index') }}" x-on:click.stop class="underline hover:text-gray-300">{{ __('Privacy Policy') }}</a>
    </span>
</footer>
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "patch_footer: footer pattern not found\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "patch_footer: patched $path\n";
EOF
RUN php /tmp/add_terms_privacy_footer_links.php && rm /tmp/add_terms_privacy_footer_links.php

# New feature: a curated, switch-based settings page in Housekeeping. The existing
# EmulatorSettingResource is a generic raw key/value CRUD grid over `emulator_settings`
# (378 rows spanning everything from trading to Netty thread-pool sizing) -- this adds a
# second, separate page (leaving that one untouched) with friendly labels/descriptions and
# real Toggle/number/select inputs for a curated first batch of the most relevant keys.
# Saving writes the changed rows, then triggers a live reload over the emulator's existing
# RCON bridge (App\Contracts\Rcon, already shipped/tested in this codebase -- reused as-is)
# by running the emulator's own ":update_config" chat command, so most changes apply
# without a restart. A handful of low-level keys (thread/connection pool sizes, debug
# flags) are flagged restart-required since ConfigurationManager.reload() confirmed does
# not reconstruct already-running thread pools.
COPY <<'EOF' /app/config/emulator_setting_switches.php
<?php

/*
 * Curated subset of the emulator's `emulator_settings` table, rendered as real
 * switches/sliders/selects by App\Filament\Pages\EmulatorSettingSwitches instead of
 * raw key/value text boxes. This is intentionally NOT every one of the ~380 rows in
 * that table -- only the ones worth a friendly label today. Anything not listed here
 * is still reachable through the existing raw Emulator Settings resource.
 *
 * Field shape:
 *   key              emulator_settings.key (exact string)
 *   label            short human label
 *   description      one sentence, shown as helper text
 *   type             'toggle' | 'number' | 'select' | 'textarea'
 *   min / max        for type 'number'
 *   options          value => label map, for type 'select'
 *   restart_required true if a live ":update_config" reload does NOT actually apply
 *                     the change (e.g. thread pools / connection pools that are only
 *                     ever constructed once at process startup)
 */

return [
    'Hotel Identity & Economy' => [
        [
            'key' => 'hotel.name',
            'label' => 'Hotel Name',
            'description' => 'The hotel\'s display name.',
            'type' => 'textarea',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.auto.credits.enabled',
            'label' => 'Auto Credits',
            'description' => 'Automatically grant online users credits on an interval.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.auto.credits.amount',
            'label' => 'Auto Credits Amount',
            'description' => 'Credits granted each interval, if Auto Credits is enabled.',
            'type' => 'number',
            'min' => 0,
            'max' => 10000,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.auto.credits.interval',
            'label' => 'Auto Credits Interval (seconds)',
            'description' => 'How often Auto Credits pays out.',
            'type' => 'number',
            'min' => 30,
            'max' => 86400,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.auto.points.enabled',
            'label' => 'Auto Activity Points',
            'description' => 'Automatically grant online users activity points on an interval.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.auto.points.amount',
            'label' => 'Auto Activity Points Amount',
            'description' => 'Activity points granted each interval, if enabled.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.max.duckets',
            'label' => 'Max Duckets Per User',
            'description' => 'Hard cap on how many duckets (seasonal currency) a single user can hold.',
            'type' => 'number',
            'min' => 0,
            'max' => 100000000,
            'restart_required' => false,
        ],
    ],

    'Rooms & Furni' => [
        [
            'key' => 'hotel.room.furni.max',
            'label' => 'Max Furni Per Room',
            'description' => 'Maximum number of furni items allowed in a single room.',
            'type' => 'number',
            'min' => 1,
            'max' => 10000,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.floorplan.max.widthlength',
            'label' => 'Max Floor Width/Length',
            'description' => 'Maximum width or length (in tiles) a custom room floorplan can have.',
            'type' => 'number',
            'min' => 1,
            'max' => 128,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.floorplan.max.totalarea',
            'label' => 'Max Floor Total Area',
            'description' => 'Maximum total tile area a custom room floorplan can have.',
            'type' => 'number',
            'min' => 1,
            'max' => 65536,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.jukebox.limit.normal',
            'label' => 'Jukebox Song Limit (Normal Room)',
            'description' => 'How many songs can be queued on a normal room\'s jukebox.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.jukebox.limit.large',
            'label' => 'Jukebox Song Limit (Large Room)',
            'description' => 'How many songs can be queued on a large room\'s jukebox.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.room.stickies.max',
            'label' => 'Max Sticky Notes Per Room',
            'description' => 'Maximum number of sticky notes (post-its) allowed in a single room.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
    ],

    'Catalog & Shop' => [
        [
            'key' => 'catalog.guild.price',
            'label' => 'Group Creation Price',
            'description' => 'Credits charged to create a Habbo Group.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
        [
            'key' => 'catalog.guild.hc_required',
            'label' => 'Group Creation Requires HC',
            'description' => 'Require an active Habbo Club subscription to create a Group.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.catalog.recycler.enabled',
            'label' => 'Enable Recycler',
            'description' => 'Allow users to recycle furni for a reward via the Furni-Matic.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'recycler.value',
            'label' => 'Recycler Reward (Duckets)',
            'description' => 'Duckets granted per completed recycler bundle.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.ecotron.enabled',
            'label' => 'Enable Furni-Matic Box Opening',
            'description' => 'Allow the wrapped reward box from recycling to actually be opened.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.catalog.ltd.limit.enabled',
            'label' => 'Enforce Limited Edition Purchase Limits',
            'description' => 'Cap how many of a Limited Edition item a single user can buy per day.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.purchase.ltd.limit.daily.total',
            'label' => 'Daily LTD Purchase Limit (Total)',
            'description' => 'Max total Limited Edition items a single user may buy per day, if the limit above is enforced.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
    ],

    'Bots & Pets' => [
        [
            'key' => 'hotel.bots.max.room',
            'label' => 'Max Bots Per Room',
            'description' => 'Maximum number of bots a single room can hold.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.bots.max.inventory',
            'label' => 'Max Bots In Inventory',
            'description' => 'Maximum number of bots a single user can own at once.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.pets.max.room',
            'label' => 'Max Pets Per Room',
            'description' => 'Maximum number of pets a single room can hold.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.pets.max.inventory',
            'label' => 'Max Pets In Inventory',
            'description' => 'Maximum number of pets a single user can own at once.',
            'type' => 'number',
            'min' => 0,
            'max' => 1000,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.bot.chat.minimum.interval',
            'label' => 'Bot Chat Minimum Interval (seconds)',
            'description' => 'Minimum time between a bot\'s automatic chat lines.',
            'type' => 'number',
            'min' => 1,
            'max' => 300,
            'restart_required' => false,
        ],
    ],

    'Trading & Marketplace' => [
        [
            'key' => 'hotel.trading.enabled',
            'label' => 'Enable Trading',
            'description' => 'Allow users to trade furni/items with each other in rooms.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.trading.requires.perk',
            'label' => 'Trading Requires Perk',
            'description' => 'Require a trade permission/perk before a user can trade at all.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.marketplace.enabled',
            'label' => 'Enable Marketplace',
            'description' => 'Allow users to list and buy furni through the Marketplace.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
    ],

    'Moderation & Chat' => [
        [
            'key' => 'hotel.wordfilter.enabled',
            'label' => 'Enable Word Filter',
            'description' => 'Filter banned words out of chat, names and mottos.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.wordfilter.automute',
            'label' => 'Auto-Mute Word Filter Violations',
            'description' => 'Automatically mute a user who triggers the word filter.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.flood.mute.time',
            'label' => 'Flood Mute Duration (seconds)',
            'description' => 'How long a user is muted for chat-flooding.',
            'type' => 'number',
            'min' => 0,
            'max' => 3600,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.chat.max.length',
            'label' => 'Max Chat Message Length',
            'description' => 'Maximum number of characters allowed in one chat message.',
            'type' => 'number',
            'min' => 1,
            'max' => 500,
            'restart_required' => false,
        ],
        [
            'key' => 'hotel.sanctions.enabled',
            'label' => 'Enable Sanctions',
            'description' => 'Allow moderators to issue formal sanctions against users.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
    ],

    'Subscriptions & HC' => [
        [
            'key' => 'subscriptions.hc.payday.enabled',
            'label' => 'Enable HC Payday',
            'description' => 'Periodically refund a percentage of an HC subscriber\'s spending as credits.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
        [
            'key' => 'subscriptions.hc.payday.percentage',
            'label' => 'HC Payday Percentage',
            'description' => 'Percentage of recent spend refunded on HC Payday.',
            'type' => 'number',
            'min' => 0,
            'max' => 100,
            'restart_required' => false,
        ],
        [
            'key' => 'subscriptions.hc.discount.enabled',
            'label' => 'Enable HC Renewal Discount',
            'description' => 'Offer a discount when a subscriber\'s HC is about to expire.',
            'type' => 'toggle',
            'restart_required' => false,
        ],
    ],

    'Debug, Logging & Low-Level' => [
        [
            'key' => 'debug.mode',
            'label' => 'Debug Mode',
            'description' => 'Enable verbose emulator debug output.',
            'type' => 'toggle',
            'restart_required' => true,
        ],
        [
            'key' => 'logging.debug',
            'label' => 'Debug Logging',
            'description' => 'Enable debug-level log lines.',
            'type' => 'toggle',
            'restart_required' => true,
        ],
        [
            'key' => 'io.bossgroup.threads',
            'label' => 'Network Boss Threads',
            'description' => 'Netty boss thread pool size. Only takes effect on the next full restart.',
            'type' => 'number',
            'min' => 1,
            'max' => 16,
            'restart_required' => true,
        ],
        [
            'key' => 'io.workergroup.threads',
            'label' => 'Network Worker Threads',
            'description' => 'Netty worker thread pool size. Only takes effect on the next full restart.',
            'type' => 'number',
            'min' => 1,
            'max' => 64,
            'restart_required' => true,
        ],
        [
            'key' => 'db.pool.minsize',
            'label' => 'DB Connection Pool Min Size',
            'description' => 'Minimum MySQL connections kept open. Only takes effect on the next full restart.',
            'type' => 'number',
            'min' => 1,
            'max' => 64,
            'restart_required' => true,
        ],
        [
            'key' => 'db.pool.maxsize',
            'label' => 'DB Connection Pool Max Size',
            'description' => 'Maximum MySQL connections allowed open. Only takes effect on the next full restart.',
            'type' => 'number',
            'min' => 1,
            'max' => 128,
            'restart_required' => true,
        ],
        [
            'key' => 'runtime.threads',
            'label' => 'Runtime Thread Pool Size',
            'description' => 'General worker thread pool size. Only takes effect on the next full restart.',
            'type' => 'number',
            'min' => 1,
            'max' => 64,
            'restart_required' => true,
        ],
    ],
];
EOF

COPY <<'EOF' /app/app/Filament/Pages/EmulatorSettingSwitches.php
<?php

namespace App\Filament\Pages;

use App\Contracts\Rcon;
use App\Emulator\Data\Feature;
use App\Emulator\Emulator;
use App\Exceptions\RconConnectionException;
use App\Models\EmulatorSetting;
use App\Services\HousekeepingPermissionsService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class EmulatorSettingSwitches extends Page
{
    use InteractsWithForms;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-adjustments-vertical';

    protected static string|\UnitEnum|null $navigationGroup = 'Hotel';

    protected static ?string $navigationLabel = 'Setting Switches';

    protected static ?string $title = 'Emulator Setting Switches';

    protected string $view = 'filament.pages.emulator-setting-switches';

    /** @var array<string, mixed> */
    public ?array $data = [];

    public static function canAccess(): bool
    {
        $user = auth()->user();

        return Emulator::supports(Feature::EmulatorSettings)
            && $user !== null
            && app(HousekeepingPermissionsService::class)->allows($user, 'manage_emulator_settings_switches');
    }

    /**
     * emulator_settings.key values are dotted strings ("hotel.trading.enabled"), but
     * Filament/Livewire form field names treat dots as nested-array path separators, not
     * literal characters -- so the raw key can't be used as a field name without every
     * value silently landing in the wrong nested slot. Field names use this sanitized
     * form throughout; the real key is only ever read from/written to the database.
     */
    private function fieldName(string $key): string
    {
        return str_replace('.', '__', $key);
    }

    public function mount(): void
    {
        $keys = collect(config('emulator_setting_switches'))
            ->flatten(1)
            ->pluck('key');

        $current = EmulatorSetting::query()->whereIn('key', $keys)->pluck('value', 'key');

        foreach (config('emulator_setting_switches') as $fields) {
            foreach ($fields as $field) {
                $this->data[$this->fieldName($field['key'])] = $this->castIn($field, $current[$field['key']] ?? null);
            }
        }
    }

    public function form(Schema $schema): Schema
    {
        $sections = [];

        foreach (config('emulator_setting_switches') as $category => $fields) {
            $sections[] = Section::make($category)
                ->collapsible()
                ->schema(array_map(fn (array $field) => $this->componentFor($field), $fields));
        }

        return $schema->components($sections)->statePath('data');
    }

    /**
     * @param  array<string, mixed>  $field
     */
    private function componentFor(array $field)
    {
        $helperText = $field['description'] ?? null;

        if (! empty($field['restart_required'])) {
            $helperText = trim(($helperText ?? '') . ' (Requires a full emulator restart to take effect.)');
        }

        $name = $this->fieldName($field['key']);

        return match ($field['type']) {
            'toggle' => Toggle::make($name)
                ->label($field['label'])
                ->helperText($helperText),

            'number' => TextInput::make($name)
                ->label($field['label'])
                ->helperText($helperText)
                ->numeric()
                ->minValue($field['min'] ?? null)
                ->maxValue($field['max'] ?? null),

            'select' => Select::make($name)
                ->label($field['label'])
                ->helperText($helperText)
                ->options($field['options'] ?? []),

            default => Textarea::make($name)
                ->label($field['label'])
                ->helperText($helperText)
                ->rows(2),
        };
    }

    /**
     * @param  array<string, mixed>  $field
     */
    private function castIn(array $field, ?string $rawValue): mixed
    {
        if ($rawValue === null) {
            return $field['type'] === 'toggle' ? false : null;
        }

        return match ($field['type']) {
            'toggle' => $rawValue === '1',
            'number' => is_numeric($rawValue) ? $rawValue + 0 : $rawValue,
            default => $rawValue,
        };
    }

    /**
     * @param  array<string, mixed>  $field
     */
    private function castOut(array $field, mixed $value): string
    {
        return match ($field['type']) {
            'toggle' => $value ? '1' : '0',
            default => (string) $value,
        };
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('save')
                ->label('Save & Apply Live')
                ->action('save'),
        ];
    }

    public function save(): void
    {
        $registry = collect(config('emulator_setting_switches'))->flatten(1)->keyBy('key');
        $state = $this->form->getState();

        $changed = [];

        foreach ($registry as $key => $field) {
            $newValue = $this->castOut($field, $state[$this->fieldName($key)] ?? null);
            $currentValue = EmulatorSetting::query()->find($key)?->value;

            if ($currentValue !== $newValue) {
                EmulatorSetting::query()->updateOrCreate(['key' => $key], ['value' => $newValue]);
                $changed[] = $field;
            }
        }

        if (empty($changed)) {
            Notification::make()->title('Nothing changed')->send();

            return;
        }

        $needsRestart = collect($changed)->contains('restart_required', true);

        try {
            $response = app(Rcon::class)->sendCommand('executecommand', [
                'user_id' => auth()->id(),
                'command' => ':update_config',
            ]);

            if ($response->successful() && ! $needsRestart) {
                Notification::make()
                    ->success()
                    ->title('Applied live')
                    ->body('Settings saved and reloaded on the running server -- no restart needed.')
                    ->send();
            } elseif ($response->successful()) {
                Notification::make()
                    ->warning()
                    ->title('Saved -- restart required')
                    ->body('Live reload ran, but some changed settings only take effect after restarting the emulator.')
                    ->send();
            } else {
                Notification::make()
                    ->danger()
                    ->title('Saved -- live reload rejected')
                    ->body('Settings saved to the database, but the emulator rejected the reload command: ' . $response->message)
                    ->send();
            }
        } catch (RconConnectionException $e) {
            Notification::make()
                ->danger()
                ->title('Saved -- live reload failed')
                ->body('Settings saved to the database, but could not reach the emulator over RCON (' . $e->getMessage() . '). Run :update_config in-game or restart the emulator.')
                ->send();
        }
    }
}
EOF

COPY <<'EOF' /app/resources/views/filament/pages/emulator-setting-switches.blade.php
<x-filament-panels::page>
    {{ $this->form }}
</x-filament-panels::page>
EOF

COPY <<'EOF' /tmp/add_emulator_setting_switches_permission.php
<?php
$path = "/app/database/seeders/HousekeepingPermissionSeeder.php";
$content = file_get_contents($path);

$old = <<<'OLD'
            [
                'permission' => 'manage_emulator_settings',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to manage emulator settings',
            ],
OLD;

$new = <<<'NEW'
            [
                'permission' => 'manage_emulator_settings',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to manage emulator settings',
            ],
            [
                'permission' => 'manage_emulator_settings_switches',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to manage curated emulator setting switches (can trigger a live RCON config reload)',
            ],
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "add_emulator_setting_switches_permission: anchor not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "add_emulator_setting_switches_permission: patched $path\n";
EOF
RUN php /tmp/add_emulator_setting_switches_permission.php && rm /tmp/add_emulator_setting_switches_permission.php

# Upstream bug, found while testing the settings-switches page above: the `users` table
# has no `email` column at all (the real column is `mail`), but Filament's stock Login
# page hardcodes 'email' as the credential array key it hands to the Eloquent user
# provider -- so every Housekeeping password login attempt throws "Unknown column
# 'email' in 'where clause'" before the password is even checked. Adds a thin Login
# subclass that maps the credential lookup to the real `mail` column (the visible form
# field can stay named 'email', that's just the Livewire form state key) and wires it
# into the panel provider in place of the stock class.
COPY <<'EOF' /app/app/Filament/Auth/Login.php
<?php

namespace App\Filament\Auth;

use Filament\Auth\Pages\Login as BaseLogin;
use SensitiveParameter;

/**
 * Upstream bug: the User model's login column is `mail`, not `email` (there is no
 * `email` column on `users` at all -- see app/Models/User.php's $fillable/$hidden and
 * the `mail`/`mail_verified` properties). Filament's stock Login page hardcodes 'email'
 * as the credential array key it hands to the Eloquent user provider, so every password
 * login attempt fails with "Unknown column 'email' in 'where clause'" before the
 * password is even checked. The visible form field can stay named/keyed 'email' (that's
 * just the Livewire form state path); only the actual credential lookup needs to target
 * the real column.
 */
class Login extends BaseLogin
{
    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function getCredentialsFromFormData(#[SensitiveParameter] array $data): array
    {
        return [
            'mail' => $data['email'],
            'password' => $data['password'],
        ];
    }
}
EOF

COPY <<'EOF' /tmp/fix_housekeeping_login.php
<?php
$path = "/app/app/Providers/Filament/AdminFilamentPanelProvider.php";
$content = file_get_contents($path);

$oldImport = "use App\\Http\\Middleware\\BannedMiddleware;";
$newImport = "use App\\Filament\\Auth\\Login;\nuse App\\Http\\Middleware\\BannedMiddleware;";
if (strpos($content, $oldImport) === false) {
    fwrite(STDERR, "fix_housekeeping_login: import anchor not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($oldImport, $newImport, $content);

$oldLogin = "            ->login()\n";
$newLogin = "            ->login(Login::class)\n";
if (strpos($content, $oldLogin) === false) {
    fwrite(STDERR, "fix_housekeeping_login: ->login() call not found (upstream may have changed)\n");
    exit(1);
}
$content = str_replace($oldLogin, $newLogin, $content);

file_put_contents($path, $content);
echo "fix_housekeeping_login: patched $path\n";
EOF
RUN php /tmp/fix_housekeeping_login.php && rm /tmp/fix_housekeeping_login.php

# New feature: a Housekeeping page for reviewing in-game survey (poll) results. Upstream
# AtomCMS has no models or admin UI at all for the polls/polls_questions/polls_answers
# tables (the whole poll system only got wired up client-side tonight). Adds thin
# read-only Eloquent models plus a bespoke page listing every survey with its response
# count, and a per-question breakdown on click -- a tally + percentage bar for
# single/multi-choice questions, a plain list of replies for free-text ones.
COPY <<'EOF' /app/app/Models/Poll.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Poll extends Model
{
    protected $table = 'polls';

    protected $guarded = [];

    public $timestamps = false;
}
EOF

COPY <<'EOF' /app/app/Models/PollQuestion.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PollQuestion extends Model
{
    protected $table = 'polls_questions';

    protected $guarded = [];

    public $timestamps = false;
}
EOF

COPY <<'EOF' /app/app/Models/PollAnswer.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * `polls_answers` has a composite primary key (poll_id, user_id, question_id) and no
 * single `id` column -- Eloquent doesn't support composite keys natively, so this model
 * is read-only via query()/where() only. Never call find()/save() on it.
 */
class PollAnswer extends Model
{
    protected $table = 'polls_answers';

    protected $guarded = [];

    public $timestamps = false;
}
EOF

COPY <<'EOF' /app/app/Filament/Pages/PollResults.php
<?php

namespace App\Filament\Pages;

use App\Models\Poll;
use App\Models\PollAnswer;
use App\Models\PollQuestion;
use App\Services\HousekeepingPermissionsService;
use Filament\Pages\Page;
use Illuminate\Support\Facades\DB;

class PollResults extends Page
{
    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-chart-bar';

    protected static string|\UnitEnum|null $navigationGroup = 'Hotel';

    protected static ?string $navigationLabel = 'Survey Results';

    protected static ?string $title = 'Survey Results';

    protected string $view = 'filament.pages.poll-results';

    public ?int $selectedPollId = null;

    public static function canAccess(): bool
    {
        $user = auth()->user();

        return $user !== null
            && app(HousekeepingPermissionsService::class)->allows($user, 'manage_poll_results');
    }

    /**
     * @return array<int, array{poll: Poll, respondents: int, activeRooms: int}>
     */
    public function polls(): array
    {
        return Poll::query()->orderByDesc('id')->get()->map(fn (Poll $poll) => [
            'poll' => $poll,
            'respondents' => PollAnswer::query()->where('poll_id', $poll->id)->where('question_id', '!=', 0)->distinct('user_id')->count('user_id'),
            'activeRooms' => DB::table('rooms')->where('poll_id', $poll->id)->count(),
        ])->all();
    }

    public function selectPoll(int $id): void
    {
        $this->selectedPollId = $id;
    }

    public function backToList(): void
    {
        $this->selectedPollId = null;
    }

    /**
     * @return array{poll: Poll, totalRespondents: int, declined: int, activeRooms: int, questions: array<int, array<string, mixed>>}|null
     */
    public function selectedStats(): ?array
    {
        if ($this->selectedPollId === null) {
            return null;
        }

        $poll = Poll::query()->find($this->selectedPollId);

        if ($poll === null) {
            return null;
        }

        $questions = PollQuestion::query()->where('poll_id', $poll->id)->orderBy('order')->get();

        $questionStats = $questions->map(function (PollQuestion $question) use ($poll) {
            $answers = PollAnswer::query()
                ->where('polls_answers.poll_id', $poll->id)
                ->where('polls_answers.question_id', $question->id)
                ->join('users', 'users.id', '=', 'polls_answers.user_id')
                ->select('polls_answers.answer', 'users.username')
                ->get();

            $options = $this->parseOptions($question->options);

            if (! empty($options)) {
                $tally = [];
                foreach ($options as $value => $label) {
                    $tally[$value] = ['label' => $label, 'count' => 0];
                }

                foreach ($answers as $answer) {
                    foreach (explode(';', $answer->answer) as $chosenValue) {
                        if (isset($tally[$chosenValue])) {
                            $tally[$chosenValue]['count']++;
                        }
                    }
                }

                return [
                    'question' => $question,
                    'type' => 'choice',
                    'total' => $answers->count(),
                    'tally' => array_values($tally),
                ];
            }

            return [
                'question' => $question,
                'type' => 'text',
                'total' => $answers->count(),
                'replies' => $answers->map(fn ($a) => ['username' => $a->username, 'text' => $a->answer])->all(),
            ];
        })->all();

        return [
            'poll' => $poll,
            'totalRespondents' => PollAnswer::query()->where('poll_id', $poll->id)->where('question_id', '!=', 0)->distinct('user_id')->count('user_id'),
            'declined' => PollAnswer::query()->where('poll_id', $poll->id)->where('question_id', 0)->count(),
            'activeRooms' => DB::table('rooms')->where('poll_id', $poll->id)->count(),
            'questions' => $questionStats,
        ];
    }

    /**
     * Parses the "Label:value;Label:value" option-string format used by
     * polls_questions.options into a [value => label] map. Returns an empty array for
     * free-text questions (which store no options at all).
     *
     * @return array<string, string>
     */
    private function parseOptions(string $optionsString): array
    {
        $options = [];

        if (trim($optionsString) === '') {
            return $options;
        }

        foreach (explode(';', $optionsString) as $entry) {
            $parts = explode(':', $entry, 2);

            if (count($parts) === 2) {
                $options[$parts[1]] = $parts[0];
            }
        }

        return $options;
    }
}
EOF

COPY <<'EOF' /app/resources/views/filament/pages/poll-results.blade.php
<x-filament-panels::page>
    @if ($this->selectedPollId === null)
        <div class="space-y-4">
            @forelse ($this->polls() as $row)
                <div class="fi-section rounded-xl bg-white p-4 shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
                    <div class="flex items-center justify-between gap-4">
                        <div>
                            <h3 class="text-base font-semibold">{{ $row['poll']->title }}</h3>
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                {{ $row['respondents'] }} {{ Str::plural('respondent', $row['respondents']) }}
                                @if ($row['activeRooms'] > 0)
                                    &middot; live in {{ $row['activeRooms'] }} {{ Str::plural('room', $row['activeRooms']) }}
                                @else
                                    &middot; not currently assigned to a room
                                @endif
                            </p>
                        </div>
                        <x-filament::button wire:click="selectPoll({{ $row['poll']->id }})">
                            View results
                        </x-filament::button>
                    </div>
                </div>
            @empty
                <p class="text-gray-500 dark:text-gray-400">No surveys created yet.</p>
            @endforelse
        </div>
    @else
        @php($stats = $this->selectedStats())

        @if ($stats)
            <x-filament::button wire:click="backToList" color="gray" class="mb-4">
                &larr; Back to all surveys
            </x-filament::button>

            <div class="space-y-6">
                <div>
                    <h2 class="text-lg font-semibold">{{ $stats['poll']->title }}</h2>
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        {{ $stats['totalRespondents'] }} {{ Str::plural('respondent', $stats['totalRespondents']) }}
                        @if ($stats['declined'] > 0)
                            &middot; {{ $stats['declined'] }} declined
                        @endif
                    </p>
                </div>

                @foreach ($stats['questions'] as $q)
                    <div class="fi-section rounded-xl bg-white p-4 shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
                        <h3 class="font-medium mb-3">{{ $q['question']->question }}</h3>

                        @if ($q['type'] === 'choice')
                            @if ($q['total'] === 0)
                                <p class="text-sm text-gray-500 dark:text-gray-400">No responses yet.</p>
                            @else
                                <div class="space-y-2">
                                    @foreach ($q['tally'] as $option)
                                        @php($pct = $q['total'] > 0 ? (int) round(($option['count'] / $q['total']) * 100) : 0)
                                        <div>
                                            <div class="flex justify-between text-sm mb-1">
                                                <span>{{ $option['label'] }}</span>
                                                <span class="text-gray-500 dark:text-gray-400">{{ $option['count'] }} ({{ $pct }}%)</span>
                                            </div>
                                            <div class="h-2 rounded-full bg-gray-100 dark:bg-gray-800">
                                                <div class="h-2 rounded-full bg-primary-500" style="width: {{ $pct }}%"></div>
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            @endif
                        @else
                            @if (empty($q['replies']))
                                <p class="text-sm text-gray-500 dark:text-gray-400">No responses yet.</p>
                            @else
                                <ul class="space-y-2">
                                    @foreach ($q['replies'] as $reply)
                                        <li class="text-sm border-l-2 border-gray-200 dark:border-gray-700 pl-3">
                                            <span class="font-medium">{{ $reply['username'] }}:</span>
                                            {{ $reply['text'] }}
                                        </li>
                                    @endforeach
                                </ul>
                            @endif
                        @endif
                    </div>
                @endforeach
            </div>
        @endif
    @endif
</x-filament-panels::page>
EOF

COPY <<'EOF' /tmp/add_poll_results_permission.php
<?php
$path = "/app/database/seeders/HousekeepingPermissionSeeder.php";
$content = file_get_contents($path);

$old = <<<'OLD'
            [
                'permission' => 'manage_emulator_settings_switches',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to manage curated emulator setting switches (can trigger a live RCON config reload)',
            ],
OLD;

$new = <<<'NEW'
            [
                'permission' => 'manage_emulator_settings_switches',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to manage curated emulator setting switches (can trigger a live RCON config reload)',
            ],
            [
                'permission' => 'manage_poll_results',
                'min_rank' => 6,
                'description' => 'The minimum rank required before being able to view in-game survey (poll) results',
            ],
NEW;

if (strpos($content, $old) === false) {
    fwrite(STDERR, "add_poll_results_permission: anchor not found (upstream may have changed)\n");
    exit(1);
}
file_put_contents($path, str_replace($old, $new, $content));
echo "add_poll_results_permission: patched $path\n";
EOF
RUN php /tmp/add_poll_results_permission.php && rm /tmp/add_poll_results_permission.php

# Install composer dependencies
RUN composer install \
    --no-interaction \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# Generate optimized autoload files
RUN composer dump-autoload --optimize


# Stage 2: Node/NPM build
FROM node:20-alpine AS npm-builder

WORKDIR /app

# Copy application files from composer stage
COPY --from=composer-builder /app /app

# Install dependencies and build assets
RUN yarn install --frozen-lockfile
RUN yarn run build:atom
RUN yarn run build:dusk

# Clean up node_modules to save space
RUN rm -rf node_modules


# Stage 3: Final image with serversideup/php (nginx + PHP-FPM)
FROM serversideup/php:8.5-fpm-nginx-alpine

ENV PHP_OPCACHE_ENABLE=1

WORKDIR /var/www/html

# Switch to root for setup
USER root

# Copy application from npm-builder
COPY --from=npm-builder --chown=www-data:www-data /app /var/www/html

# Create necessary directories and set permissions
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Custom nginx configuration for Laravel
COPY <<'EOF' /etc/nginx/server-opts.d/laravel.conf
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# CORS headers for /gamedata directory and all subdirectories
location ~ ^/gamedata/ {
    # Always add CORS headers
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
    add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
    add_header Access-Control-Allow-Credentials "false" always;
    
    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
        add_header Access-Control-Max-Age 86400 always;
        add_header Content-Type "text/plain; charset=utf-8" always;
        add_header Content-Length 0 always;
        return 204;
    }
    
    try_files $uri $uri/ @fallback;
}

# Fallback for gamedata requests
location @fallback {
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-CSRF-TOKEN" always;
    try_files $uri /index.php?$query_string;
}

# Static file caching. try_files falls through to Laravel for any matching
# extension that isn't a physical file (e.g. Livewire's dynamic /livewire/livewire.js
# route), instead of 404ing before the request ever reaches PHP-FPM.
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    try_files $uri /index.php?$query_string;
}
EOF

# PHP configuration overrides
# upload_max_filesize/post_max_size raised from 20M to 500M for the custom-video-upload
# feature -- a several-minute music video easily exceeds the old limit.
RUN echo 'max_execution_time = 300' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'upload_max_filesize = 500M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'post_max_size = 500M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'memory_limit = 256M' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.memory_consumption=256' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.interned_strings_buffer=16' >> /usr/local/etc/php/conf.d/custom.ini \
    && echo 'opcache.max_accelerated_files=10000' >> /usr/local/etc/php/conf.d/custom.ini

# Set correct ownership
RUN chown -R www-data:www-data /var/www/html

RUN install-php-extensions sockets intl gd

COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

# Switch back to www-data user
USER www-data

RUN php artisan storage:link --force --silent

# serversideup/php uses S6 overlay to manage nginx + php-fpm
# No need to specify CMD, it's handled by the base image