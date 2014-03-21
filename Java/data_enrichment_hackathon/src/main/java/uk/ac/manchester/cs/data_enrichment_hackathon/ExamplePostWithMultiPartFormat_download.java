package uk.ac.manchester.cs.data_enrichment_hackathon;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.methods.PostMethod;

import org.apache.commons.httpclient.methods.multipart.Part;
import org.apache.commons.httpclient.methods.multipart.StringPart;
import org.apache.commons.httpclient.methods.multipart.MultipartRequestEntity;
import sun.misc.BASE64Encoder;

/**
 * This is a small example program on who to do a post with a MultiPart form.
 * 
 * @author Christian Brenninkmeijer
 */
public class ExamplePostWithMultiPartFormat_download 
{
    public static void main( String[] args ) throws UnsupportedEncodingException, IOException
    {
        //Service to Post to
        String destination = "http://itol.embl.de/batch_downloader.cgi";

        //Create a MultiPart Form
        Part[] parts = new Part[3];
        parts[0] = new StringPart("format", "pdf");
        parts[1] = new StringPart("tree", "6250235351762113954057630");
        parts[2] = new StringPart("displayMode", "circular");
                
        //Prepare a post with the destination to post to
        PostMethod mPost = new PostMethod(destination);
        //Add the MultiPart Form Data
        mPost.setRequestEntity( new MultipartRequestEntity(parts, mPost.getParams()) );
        
        //Create a post client
        HttpClient client = new HttpClient(); 
        //Make the Post returing the status (hopefully 200)
        int status = client.executeMethod(mPost);
        //Get the body returned by the posy
        //System.out.println( mPost.getResponseBodyAsString() );
        InputStream stream = mPost.getResponseBodyAsStream();
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();

        int nRead;
        byte[] data = new byte[16384];

        while ((nRead = stream.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();

        byte[] myByteArray =  buffer.toByteArray();       
        
        String base64String = new BASE64Encoder().encode(myByteArray);
    }
}
