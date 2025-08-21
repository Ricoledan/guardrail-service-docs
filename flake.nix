{
  description = "Guardrail Service Documentation Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        nodeDependencies = pkgs.stdenv.mkDerivation {
          name = "node-dependencies";
          src = ./.;
          buildInputs = with pkgs; [ nodejs_20 ];
          installPhase = ''
            mkdir -p $out
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js and npm for Antora
            nodejs_20
            nodePackages.npm
            nodePackages.pnpm
            nodePackages.yarn
            
            # Git for version control
            git
            
            # Text editors and utilities
            vim
            nano
            
            # File watchers and servers
            nodePackages.http-server
            nodePackages.nodemon
            
            # AsciiDoc tools
            asciidoctor
            asciidoctor-with-extensions
            
            # Ruby for additional AsciiDoc processing
            ruby
            bundler
            
            # Build tools
            gnumake
            
            # Validation and linting
            nodePackages.prettier
            nodePackages.eslint
            
            # Shell utilities
            jq
            yq
            tree
            ripgrep
            fd
            
            # Development utilities
            direnv
            watchman
            entr
            
            # Optional: PlantUML for diagrams
            plantuml
            graphviz
          ];

          shellHook = ''
            echo "🚀 Guardrail Service Documentation Development Environment"
            echo ""
            echo "Available commands:"
            echo "  npm run build:local  - Build documentation locally"
            echo "  npm run preview      - Build and preview documentation"
            echo "  npm run validate     - Validate cross-references"
            echo "  npm run serve        - Serve built documentation"
            echo ""
            echo "First time setup:"
            echo "  1. Run: npm ci"
            echo "  2. Run: npm run build:local"
            echo ""
            
            # Set up Node environment
            export NODE_ENV=development
            export PATH="$PWD/node_modules/.bin:$PATH"
            
            # Create necessary directories if they don't exist
            mkdir -p build public .cache
            
            # Check if node_modules exists
            if [ ! -d "node_modules" ]; then
              echo "⚠️  node_modules not found. Run 'npm ci' to install dependencies."
            fi
          '';

          # Environment variables
          NODE_ENV = "development";
          ANTORA_CACHE_DIR = "./.cache/antora";
        };
      });
}