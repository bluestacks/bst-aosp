/*
 * Copyright (C) 2026 BlueStacks
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package android.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

/** @hide BlueStacks helper utilities. */
public final class BstUtils {
    private BstUtils() {}

    public static Object loadListFromFile(String filePath, Object defaultValue) {
        if (filePath == null) {
            return defaultValue;
        }
        File file = new File(filePath);
        if (!file.exists() || file.length() == 0) {
            return defaultValue;
        }
        try (FileInputStream fis = new FileInputStream(file);
                ObjectInputStream ois = new ObjectInputStream(fis)) {
            return ois.readObject();
        } catch (Exception e) {
            return defaultValue;
        }
    }

    public static boolean writeListToFile(Object data, String filePath) {
        if (filePath == null || data == null) {
            return false;
        }
        File file = new File(filePath);
        File parent = file.getParentFile();
        if (parent != null && !parent.exists() && !parent.mkdirs()) {
            return false;
        }
        try (FileOutputStream fos = new FileOutputStream(file);
                ObjectOutputStream oos = new ObjectOutputStream(fos)) {
            oos.writeObject(data);
            oos.flush();
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static String getAppNameFromPid(int pid) {
        if (pid <= 0) {
            return null;
        }
        String cmdline = readProcString("/proc/" + pid + "/cmdline");
        if (cmdline != null && !cmdline.isEmpty()) {
            return cmdline;
        }
        return readProcString("/proc/" + pid + "/comm");
    }

    private static String readProcString(String path) {
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line = reader.readLine();
            if (line == null || line.isEmpty()) {
                return null;
            }
            int nul = line.indexOf('\0');
            if (nul >= 0) {
                line = line.substring(0, nul);
            }
            return line.trim();
        } catch (IOException e) {
            return null;
        }
    }
}
