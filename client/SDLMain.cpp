// SDL_Renderer backend from https://github.com/ocornut/imgui/blob/master/examples/example_sdl3_sdlrenderer3
#include <cstdio>
#include <imgui.h>
#include <imgui_impl_sdl3.h>
#include <imgui_impl_sdlrenderer3.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_render.h>
#include <SDL3/SDL_main.h>

#include "Platform/Platform.hpp"

#include "Fonts/PlexSansIcon.h"
// Implemented by Client.cpp
extern bool clientShouldExit();

bool gShouldClose = false;

SDL_Window* gWindow = nullptr;
SDL_Renderer* gRenderer = nullptr;

void mainLoop()
{
    ImGuiIO& io = ImGui::GetIO();
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        ImGui_ImplSDL3_ProcessEvent(&event);
        if (event.type == SDL_EVENT_QUIT)
            gShouldClose = true;
        if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED && event.window.windowID == SDL_GetWindowID(gWindow))
            gShouldClose = true;
    }
    if (SDL_GetWindowFlags(gWindow) & SDL_WINDOW_MINIMIZED)
    {
        SDL_Delay(10);
        return;
    }
    // Start the Dear ImGui frame
    {
        // Platform font loading - if available
        // This is only done once per session. See @ref clientPlatformLocateFontBinary for more info.
        static int platformFontSize = 0;
        if (!platformFontSize)
        {
            const char* fontData = nullptr;
            platformFontSize = clientPlatformLocateFontBinary(&fontData);
            if (platformFontSize)
            {
                SDL_Log("Loading platform font of size %d bytes", platformFontSize);
                ImFontConfig merge_config{};
                merge_config.MergeMode = true;
                // XXX: PlexSansIcon covered latin-1 pages. New ones won't overwrite them.
                // External fonts are meant to cover missing glyphs e.g. CJK ones anyway - so this is fine.
                io.Fonts->AddFontFromMemoryTTF((void*)fontData, platformFontSize, 15.0f, &merge_config);
            }
        }
        // New frame
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();
    }    
    gShouldClose |= clientShouldExit();
    // Rendering
    {
        ImGui::Render();
        SDL_SetRenderScale(gRenderer, io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y);
        SDL_SetRenderDrawColor(gRenderer, 30, 30, 30, 255);
        SDL_RenderClear(gRenderer);
        ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), gRenderer);
        SDL_RenderPresent(gRenderer);
    }
}

void SetupMacOSStyle()
{
    ImGui::StyleColorsDark();
    auto& style = ImGui::GetStyle();

    // Geometry & spacing
    style.WindowPadding        = ImVec2(12.0f, 12.0f);
    style.WindowBorderSize     = 0.0f;
    style.WindowRounding       = 0.0f;
    style.PopupRounding        = 12.0f;
    style.PopupBorderSize      = 0.5f;
    style.FramePadding         = ImVec2(8.0f, 6.0f);
    style.FrameRounding        = 6.0f;
    style.ItemSpacing          = ImVec2(8.0f, 6.0f);
    style.ScrollbarSize        = 10.0f;
    style.ScrollbarRounding    = 5.0f;
    style.GrabRounding         = 5.0f;
    style.TabRounding          = 6.0f;
    style.TabBarOverlineSize   = 0.0f;
    style.ChildBorderSize      = 0.0f;
    style.SeparatorTextBorderSize = 1.0f;
    style.CircleTessellationMaxError = 0.01f;
    style.DisabledAlpha        = 0.4f;

    // macOS Sequoia dark mode colors
    auto& c = style.Colors;
    c[ImGuiCol_WindowBg]             = ImVec4(0.118f, 0.118f, 0.118f, 1.00f);    // #1E1E1E
    c[ImGuiCol_PopupBg]              = ImVec4(0.153f, 0.153f, 0.161f, 1.00f);    // #272729
    c[ImGuiCol_FrameBg]              = ImVec4(0.165f, 0.165f, 0.173f, 1.00f);    // #2A2A2C
    c[ImGuiCol_FrameBgHovered]       = ImVec4(0.200f, 0.200f, 0.208f, 1.00f);
    c[ImGuiCol_FrameBgActive]        = ImVec4(0.235f, 0.235f, 0.243f, 1.00f);
    c[ImGuiCol_Button]               = ImVec4(0.200f, 0.200f, 0.208f, 1.00f);    // #333335
    c[ImGuiCol_ButtonHovered]        = ImVec4(0.255f, 0.255f, 0.263f, 1.00f);    // #414143
    c[ImGuiCol_ButtonActive]         = ImVec4(0.039f, 0.518f, 1.000f, 0.90f);    // #0A84FF
    c[ImGuiCol_Text]                 = ImVec4(1.000f, 1.000f, 1.000f, 1.00f);
    c[ImGuiCol_TextDisabled]         = ImVec4(0.557f, 0.557f, 0.576f, 1.00f);    // #8E8E93
    c[ImGuiCol_Border]               = ImVec4(0.227f, 0.227f, 0.235f, 0.65f);    // #3A3A3C
    c[ImGuiCol_Separator]            = ImVec4(0.227f, 0.227f, 0.235f, 0.50f);
    c[ImGuiCol_SeparatorHovered]     = ImVec4(0.039f, 0.518f, 1.000f, 0.60f);
    c[ImGuiCol_SeparatorActive]      = ImVec4(0.039f, 0.518f, 1.000f, 0.90f);
    c[ImGuiCol_MenuBarBg]            = ImVec4(0.145f, 0.145f, 0.153f, 1.00f);    // #252527
    c[ImGuiCol_Header]               = ImVec4(0.165f, 0.165f, 0.173f, 1.00f);    // #2A2A2C
    c[ImGuiCol_HeaderHovered]        = ImVec4(0.039f, 0.518f, 1.000f, 0.30f);
    c[ImGuiCol_HeaderActive]         = ImVec4(0.039f, 0.518f, 1.000f, 0.50f);
    c[ImGuiCol_CheckMark]            = ImVec4(0.039f, 0.518f, 1.000f, 1.00f);    // #0A84FF
    c[ImGuiCol_SliderGrab]           = ImVec4(0.039f, 0.518f, 1.000f, 1.00f);
    c[ImGuiCol_SliderGrabActive]     = ImVec4(0.118f, 0.565f, 1.000f, 1.00f);
    c[ImGuiCol_Tab]                  = ImVec4(0.165f, 0.165f, 0.173f, 1.00f);    // #2A2A2C
    c[ImGuiCol_TabSelected]          = ImVec4(0.200f, 0.200f, 0.208f, 1.00f);    // #333335
    c[ImGuiCol_TabSelectedOverline]  = ImVec4(0.039f, 0.518f, 1.000f, 1.00f);    // #0A84FF
    c[ImGuiCol_TabHovered]           = ImVec4(0.039f, 0.518f, 1.000f, 0.30f);
    c[ImGuiCol_PlotHistogram]        = ImVec4(0.039f, 0.518f, 1.000f, 1.00f);    // #0A84FF
    c[ImGuiCol_PlotHistogramHovered] = ImVec4(0.118f, 0.565f, 1.000f, 1.00f);
    c[ImGuiCol_ScrollbarBg]          = ImVec4(0.118f, 0.118f, 0.118f, 0.00f);
    c[ImGuiCol_ScrollbarGrab]        = ImVec4(0.333f, 0.333f, 0.345f, 0.60f);    // #555558
    c[ImGuiCol_ScrollbarGrabHovered] = ImVec4(0.400f, 0.400f, 0.412f, 0.80f);
    c[ImGuiCol_ScrollbarGrabActive]  = ImVec4(0.467f, 0.467f, 0.478f, 1.00f);
    c[ImGuiCol_ModalWindowDimBg]     = ImVec4(0.000f, 0.000f, 0.000f, 0.85f);
    c[ImGuiCol_TitleBg]              = ImVec4(0.118f, 0.118f, 0.118f, 1.00f);
    c[ImGuiCol_TitleBgActive]        = ImVec4(0.145f, 0.145f, 0.153f, 1.00f);
    c[ImGuiCol_ResizeGrip]           = ImVec4(0.039f, 0.518f, 1.000f, 0.20f);
    c[ImGuiCol_ResizeGripHovered]    = ImVec4(0.039f, 0.518f, 1.000f, 0.40f);
    c[ImGuiCol_ResizeGripActive]     = ImVec4(0.039f, 0.518f, 1.000f, 0.70f);
}

int main(int, char**)
{
    clientPlatformInit();
    if (!SDL_Init(SDL_INIT_VIDEO))
    {
        printf("SDL_Init Error: %s\n", SDL_GetError());
        return 1;
    }
    gWindow = SDL_CreateWindow(
        "SonyHeadphonesClient",
        800, 600,
        SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY
    );
    if (!gWindow)
    {
        SDL_Log("Error: SDL_CreateWindow(): %s\n", SDL_GetError());
        return 1;
    }
    gRenderer = SDL_CreateRenderer(gWindow, nullptr);
    if (!gRenderer)
    {
        SDL_Log("Error: SDL_CreateRenderer()\n");
        return 1;
    }
    // Setup Dear ImGui context
    {
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
    }
    ImGuiIO& io = ImGui::GetIO();
    // Setup macOS-inspired style
    SetupMacOSStyle();
    // Setup Platform/Renderer backends
    {
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls
        io.ConfigErrorRecoveryEnableAssert = true; // Don't assert on errors
        ImGui_ImplSDL3_InitForSDLRenderer(gWindow, gRenderer);
        ImGui_ImplSDLRenderer3_Init(gRenderer);
    }
    // Load our default font
    {
        io.Fonts->Clear();
        io.Fonts->AddFontFromMemoryCompressedBase85TTF(kEmbedFontPlexSansIcon, 15.0f);
    }
    // Main loop

    while (!gShouldClose)
        mainLoop();

    // Cleanup
    {
        ImGui_ImplSDLRenderer3_Shutdown();
        ImGui_ImplSDL3_Shutdown();
        ImGui::DestroyContext();

        SDL_DestroyRenderer(gRenderer);
        SDL_DestroyWindow(gWindow);
        SDL_Quit();

        clientPlatformDestroy();
    }
    return 0;
}
