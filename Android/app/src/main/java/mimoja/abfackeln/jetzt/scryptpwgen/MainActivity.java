package mimoja.abfackeln.jetzt.scryptpwgen;

import android.content.ClipboardManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AlertDialog;
import android.text.InputType;
import android.view.ContextMenu;
import android.view.MenuInflater;
import android.view.textclassifier.TextClassification;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.view.MenuItem;
import android.widget.PopupWindow;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class MainActivity extends AppCompatActivity {

    // Used to load the 'native-lib' library on application startup.
    static {
        System.loadLibrary("native-lib");
    }

    List<String> mKnownSites = null;
    ArrayAdapter<String> mAdapter = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);


        //Fetch known sites
        final SharedPreferences sharedPref = getPreferences(Context.MODE_PRIVATE);
        Set<String> savedSites = sharedPref.getStringSet("knownSites", new HashSet<String>());
        mKnownSites = new ArrayList<>(savedSites);

        //Get Handle to List
        ListView siteListView = (ListView) findViewById(R.id.siteList);
        registerForContextMenu(siteListView);
        mAdapter  = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, mKnownSites);
        siteListView.setAdapter(mAdapter);

        for (String site : savedSites) {
            mAdapter.add(site);
        }

        mAdapter.notifyDataSetChanged();

        // site List
        siteListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, final View view, int i, long l) {

                AlertDialog.Builder builder = new AlertDialog.Builder(MainActivity.this);
                builder.setTitle("Choose an action")
                        .setItems(R.array.actions, new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int which) {
                                final String chosen = ((TextView)view).getText().toString();
                                final EditText userInput = new EditText(MainActivity.this);
                                userInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
                                switch (which){
                                    case 0:
                                        createTextDialog(userInput, new DialogInterface.OnClickListener() {
                                            public void onClick(DialogInterface dialog, int id) {
                                                String masterPasswd = userInput.getText().toString();
                                                String passwd = generatePassword(chosen, masterPasswd);
                                                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                                                clipboard.setText(passwd);
                                                Toast.makeText(MainActivity.this, "Password generated", Toast.LENGTH_LONG).show();
                                            }
                                        });
                                        break;
                                    case 1:
                                        createTextDialog(userInput, new DialogInterface.OnClickListener() {
                                            public void onClick(DialogInterface dialog, int id) {
                                                String masterPasswd = userInput.getText().toString();
                                                String passwd = generatePassword(chosen, masterPasswd);
                                                AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(MainActivity.this);
                                                alertDialogBuilder.setTitle(passwd).setCancelable(true).show();
                                                Toast.makeText(MainActivity.this, "Password generated", Toast.LENGTH_LONG).show();
                                            }
                                        });

                                        break;
                                    case 2:
                                        mAdapter.remove(chosen);
                                        saveItemList();
                                        Toast.makeText(MainActivity.this, "Deleted", Toast.LENGTH_LONG).show();
                                        break;
                                }
                            }
                        });
                builder.create().show();

            }
        });

        // Add button
        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                final EditText userInput = new EditText(MainActivity.this);
                createTextDialog(userInput, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        String site = userInput.getText().toString();
                        if(site.length() != 0){
                            //Show on screen
                            if(mKnownSites.contains(site)){
                                Toast.makeText(MainActivity.this, "Already cointained", Toast.LENGTH_LONG).show();
                                return;
                            }
                            mKnownSites.add(site);
                            saveItemList();
                        }
                    }
                });
            }
        });

    }

    public void createTextDialog(EditText userInput, DialogInterface.OnClickListener listener){

        final AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(MainActivity.this);
        alertDialogBuilder.setView(userInput);
        alertDialogBuilder
                .setCancelable(false)
                .setPositiveButton("Go",listener)
                .setNegativeButton("Cancel",
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog,int id) {
                                dialog.dismiss();
                            }
                        }
                );

        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        userInput.requestFocus();
    }

    public void saveItemList(){
        mAdapter.notifyDataSetChanged();

        final SharedPreferences sharedPref = getPreferences(Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.clear();
        editor.putStringSet("knownSites", new HashSet<>(mKnownSites));
        editor.commit();
    }

    public native String generatePassword(String site, String password);
}
