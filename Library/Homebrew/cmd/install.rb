@@ -184,6 +184,14 @@ def install
           # FormulaInstaller will handle this case.
           formulae << f
         end
+
+        # Even if we don't install this formula mark it as no longer just
+        # installed as a dependency.
+        next unless f.opt_prefix.directory?
+        keg = Keg.new(f.opt_prefix.resolved_path)
+        tab = Tab.for_keg(keg)
+        tab.installed_on_request = true
+        tab.write
       end
 
       perform_preinstall_checks