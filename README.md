# Mouse Moover

**Auto Mouse Mover**

Mouse Moover is a Flutter desktop application that simulates user activity by automatically moving the mouse cursor at regular intervals. This can help prevent screen savers from activating or your system from locking due to inactivity.

## Features

- **Automatic Mouse Movement:**  
  Moves the cursor to random positions on the screen every 2 seconds when activated.

- **User Input Detection:**  
  Listens for mouse and keyboard events. Any user input will stop or reset the automatic movement to avoid interference while actively using the computer.

- **Inactivity Timer:**  
  If no input is detected for a specified period (default is 15 seconds), the application automatically reactivates the mouse movement. This duration is configurable via the settings panel.

- **System Tray Integration:**  
  The application integrates with the system tray:
  - Right-click for a context menu to toggle mouse movement, show the window, or exit the application.
  - Left-click (or mouse down) on the tray icon brings the application window to the forefront.

- **Fixed Window Configuration:**  
  The window is set to a fixed size (500x850) and uses platform-specific window management to prevent accidental closure.

- **Cross-Platform Support:**  
  Supports Windows, macOS, and Linux by using platform-specific implementations for controlling the mouse cursor.

## Build Prerequisites

If you want to build yourself, before running the application, make sure you have the following:

- **Flutter SDK:**  
  [Install Flutter](https://docs.flutter.dev/get-started/install) if you haven't already.

- **Platform-Specific Dependencies:**  
  - **Linux:**  
    Install `xdotool` (e.g., `sudo apt-get install xdotool`).
  - **macOS:**  
    Install `cliclick` using Homebrew (e.g., `brew install cliclick`).
  - **Windows:**  
    No additional setup is required.

- **Other Dependencies:**  
  The project uses packages such as `flutter_animate`, `google_fonts`, `tray_manager`, and `window_manager`. These will be installed automatically via Flutter's package manager when you run `flutter pub get`.

## Getting Started

Follow these steps to get up and running:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/Taoshan98/mouse-moover.git
   cd mouse-moover
   ```

2. **Install Dependencies:**

   Run the following command to install the necessary packages:

   ```bash
   flutter pub get
   ```

3. **Run the Application:**

   Launch the application on your desktop:

   ```bash
   flutter run
   ```

   Alternatively, you can build a desktop executable for your platform.

## Usage

- **Toggle Mouse Movement:**  
  Use the main UI button or the system tray menu to start or stop the automatic mouse movement.

- **Settings Panel:**  
  Click the settings icon on the app bar to configure the inactivity timer (in seconds). This timer determines how long the application waits without detecting user input before reactivating the mouse movement.

- **System Tray:**  
  - **Left-click** the tray icon to bring up the application window.
  - **Right-click** the tray icon to display the context menu, allowing you to show the window, toggle mouse movement, or exit the application.

## Contributing

Contributions are welcome! If you have suggestions or improvements, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
