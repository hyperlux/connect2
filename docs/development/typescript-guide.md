# Development Memory

[Previous content through "Troubleshooting Steps" remains unchanged...]

### Production Database Verification

1. Verify PostgreSQL Installation on Production:
   ```bash
   # Check if PostgreSQL is installed and running
   sudo systemctl status postgresql
   
   # Verify PostgreSQL version matches development
   psql --version
   ```

[Previous database verification content through "Schema Migration Notes" remains unchanged...]

### TypeScript Configuration and Common Issues

1. Required Dependencies:
   ```bash
   # Core TypeScript dependencies
   npm install --save-dev typescript @types/react @types/react-dom

   # Check versions are installed
   npm list typescript @types/react @types/react-dom
   ```

2. TypeScript Configuration:
   ```json
   // tsconfig.json
   {
     "compilerOptions": {
       "target": "ES2020",
       "useDefineForClassFields": true,
       "lib": ["ES2020", "DOM", "DOM.Iterable"],
       "module": "ESNext",
       "skipLibCheck": true,
       "allowJs": true,
       "moduleResolution": "bundler",
       "allowImportingTsExtensions": true,
       "resolveJsonModule": true,
       "isolatedModules": true,
       "noEmit": true,
       "jsx": "react-jsx",
       "esModuleInterop": true,
       "strict": true,
       "noUnusedLocals": false,
       "noUnusedParameters": false,
       "typeRoots": ["./node_modules/@types", "./src/types"],
       "types": ["react", "react-dom", "vite/client"]
     },
     "include": ["src"],
     "references": [{ "path": "./tsconfig.node.json" }]
   }
   ```

3. Common TypeScript Issues:
   - JSX namespace missing: Import React in files using JSX
   - Missing type definitions: Install @types packages
   - Implicit any types: Use proper type annotations
   - JSX.IntrinsicElements errors: Ensure proper React types
   - React hooks type errors: Ensure proper React type declarations in vite-env.d.ts
   - Theme and styling type errors: Define proper theme type declarations
   - Component library type errors: Add proper type definitions for UI libraries

4. Type Declaration Files:
   ```typescript
   // vite-env.d.ts
   /// <reference types="vite/client" />
   /// <reference types="react" />
   /// <reference types="react-dom" />

   // File type declarations
   declare module '*.svg' {
     import * as React from 'react';
     const ReactComponent: React.FunctionComponent<React.SVGProps<SVGSVGElement>>;
     export default ReactComponent;
   }

   // React namespace augmentation
   declare namespace React {
     export import useState = React.useState;
     export import useEffect = React.useEffect;
     export import useCallback = React.useCallback;
     export import useMemo = React.useMemo;
     export import useRef = React.useRef;
     
     interface FormEvent<T = Element> extends SyntheticEvent<T> {
       readonly target: EventTarget & T;
     }
     
     interface ChangeEvent<T = Element> extends SyntheticEvent<T> {
       readonly target: EventTarget & T;
     }
   }

   // JSX type declarations (jsx.d.ts)
   declare global {
     namespace JSX {
       interface IntrinsicElements {
         div: React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>;
         // ... other element definitions
       }
       interface Element extends React.ReactElement<any, any> { }
       interface ElementClass extends React.Component<any> { }
     }
   }
   ```

5. Build Issues Solutions:
   - Disable strict unused checks if causing false positives:
     ```json
     "noUnusedLocals": false,
     "noUnusedParameters": false
     ```
   - Add proper type roots configuration:
     ```json
     "typeRoots": ["./node_modules/@types", "./src/types"]
     ```
   - Include necessary type references:
     ```typescript
     /// <reference types="vite/client" />
     /// <reference types="react" />
     /// <reference types="react-dom" />
     ```
   - Augment React namespace for hooks:
     ```typescript
     declare namespace React {
       export import useState = React.useState;
       export import useEffect = React.useEffect;
       // ... other hooks
     }
     ```
   - Add theme type declarations:
     ```typescript
     // theme.d.ts
     declare module 'tailwind-theme' {
       interface ThemeColors {
         'dark-card': string;
         'dark-primary': string;
         // ... other theme colors
       }
     }
     ```

6. Development Best Practices:
   ```bash
   # Check for type errors before commit
   tsc --noEmit

   # Update all @types packages
   npm update @types/*
   ```

7. IDE Configuration:
   - Use VS Code with TypeScript support
   - Enable "TypeScript > Suggest: Enabled" setting
   - Install ESLint and Prettier extensions

8. Pre-commit Checks:
   ```bash
   # Add to package.json scripts
   "scripts": {
     "typecheck": "tsc --noEmit",
     "lint": "eslint src --ext .ts,.tsx"
   }
   ```

9. Troubleshooting Steps:
   - Clear TypeScript cache: `rm -rf node_modules/.cache/typescript`
   - Rebuild node_modules: `rm -rf node_modules && npm install`
   - Update TypeScript: `npm install typescript@latest`
   - Check tsconfig paths match project structure
   - Verify type declarations in vite-env.d.ts and jsx.d.ts
   - Ensure React namespace augmentations are properly defined
   - Check theme type definitions match Tailwind configuration
   - Verify component library type definitions are up to date

10. Production Build Issues:
    - Problem: Type definition errors on production server
      ```bash
      error TS2688: Cannot find type definition file for 'react'.
      error TS2688: Cannot find type definition file for 'react-dom'.
      error TS2688: Cannot find type definition file for 'vite/client'.
      ```
    
    - Solution: Remove explicit types from tsconfig.json and rely on typeRoots
      ```json
      // tsconfig.json
      {
        "compilerOptions": {
          // Remove "types" array and use typeRoots instead
          "typeRoots": ["./node_modules/@types", "./src/types"],
          // Other settings remain unchanged...
        }
      }
      ```
    
    - Alternative Solutions:
      1. Install type definitions on production:
         ```bash
         npm install --save-dev @types/react @types/react-dom
         ```
      2. Move type packages to regular dependencies:
         ```bash
         npm install @types/react @types/react-dom
         ```
      3. Use skipLibCheck: true in tsconfig.json to bypass strict type checking

    - Best Practice:
      - Keep development and production environments consistent
      - Include type packages in package.json dependencies if needed in production
      - Document any environment-specific TypeScript configurations
      - Maintain comprehensive theme and component type definitions

[Previous "Production Server Details" and other sections remain unchanged...]
