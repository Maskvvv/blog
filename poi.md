在网上也是找了好久才找到的一些比较好的资料，我自己总结梳理了一下，方便后面各位小伙伴使用。

## 1、效果图

![img](https://img-blog.csdnimg.cn/5b948c5d37a349b4b0cd5e30366a2cfb.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5rKf5aOR5a2m57yW56iL,size_20,color_FFFFFF,t_70,g_se,x_16)

所需的架包百度网盘：

[百度链接![icon-default.png?t=LA92](https://csdnimg.cn/release/blog_editor_html/release1.9.5/ckeditor/plugins/CsdnLink/icons/icon-default.png?t=LA92)https://pan.baidu.com/s/1oGsL7hSo71I76aQ3E7GJxA](https://pan.baidu.com/s/1oGsL7hSo71I76aQ3E7GJxA) 

提取码: 3axi

## 2、实现代码

### 2.1 word转pdf实现

```java
package com.ruoyi.common.utils.file;



 



import com.aspose.words.*;



import com.aspose.words.Shape;



 



import java.awt.*;



import java.io.File;



import java.io.FileOutputStream;



import java.io.IOException;



 



/**



 * word转pdf



 */



public class WordToPdfUtils {



 



    /**



     *  word转pdf



     * @param inPath word文件路径



     * @param outPath 输出路径



     */



    public static boolean doc2pdf(String inPath, String outPath) {



        FileOutputStream os =null;



        try {



            File file = new File(outPath); // 新建一个空白pdf文档



            os = new FileOutputStream(file);



            Document doc = new Document(inPath); // Address是将要被转化的word文档



            //添加水印



            //insertWatermarkText(doc,str);



            //保存pdf文件



            doc.save(os, SaveFormat.PDF);



        } catch (Exception e) {



            e.printStackTrace();



            return false;



        }finally{



            if(os!=null){



                try {



                    os.close();



                } catch (IOException e) {



                    e.printStackTrace();



                }



            }



            return true;



        }



    }



 



 



    /**



     *



     * @Title: insertWatermarkText



     * @Description: PDF生成水印



     * @author mzl



     * @param doc



     * @param watermarkText



     * @throws Exception



     * @throws



     */



    private static void insertWatermarkText(Document doc, String watermarkText) throws Exception



    {



        if (!watermarkText.equals("")&&null!=watermarkText){



            Shape watermark = new Shape(doc, ShapeType.TEXT_PLAIN_TEXT);



            //水印内容



            watermark.getTextPath().setText(watermarkText);



            //水印字体



            watermark.getTextPath().setFontFamily("宋体");



            //水印宽度



            watermark.setWidth(400);



            //水印高度



            watermark.setHeight(100);



            //旋转水印



            watermark.setRotation(-30);



            //水印颜色



            watermark.getFill().setColor(Color.lightGray);



            watermark.setStrokeColor(Color.lightGray);



            watermark.setRelativeHorizontalPosition(RelativeHorizontalPosition.PAGE);



            watermark.setRelativeVerticalPosition(RelativeVerticalPosition.PAGE);



            watermark.setWrapType(WrapType.NONE);



            watermark.setVerticalAlignment(VerticalAlignment.CENTER);



            watermark.setHorizontalAlignment(HorizontalAlignment.CENTER);



            Paragraph watermarkPara = new Paragraph(doc);



            watermarkPara.appendChild(watermark);



            for (Section sect : doc.getSections())



            {



                insertWatermarkIntoHeader(watermarkPara, sect, HeaderFooterType.HEADER_PRIMARY);



                insertWatermarkIntoHeader(watermarkPara, sect, HeaderFooterType.HEADER_FIRST);



                insertWatermarkIntoHeader(watermarkPara, sect, HeaderFooterType.HEADER_EVEN);



            }



        }



    }



    private static void insertWatermarkIntoHeader(Paragraph watermarkPara, Section sect, int headerType) throws Exception



    {



        HeaderFooter header = sect.getHeadersFooters().getByHeaderFooterType(headerType);



        if (header == null)



        {



            header = new HeaderFooter(sect.getDocument(), headerType);



            sect.getHeadersFooters().add(header);



        }



        header.appendChild(watermarkPara.deepClone(true));



    }



 



}
```

### 2.2 excel转pdf实现

```java
package com.ruoyi.common.utils.file;



 



 



import com.aspose.cells.License;



import com.aspose.cells.SaveFormat;



import com.aspose.cells.Workbook;



 



import java.io.File;



import java.io.FileOutputStream;



import java.io.InputStream;



 



/**



 * excel转pdf帮助类



 */



public class ExcelToPdfUtils {



 



    /**



     * excel转pdf方法



     * @param Address  原路径excel



     * @param putPath  转换pdf后的路径



     */



    public static void excel2pdf(String Address,String putPath) {



        if (!getLicense()) {          // 验证License 若不验证则转化出的pdf文档会有水印产生



            return ;



        }



        try {



            File pdfFile = new File(putPath); // 输出路径



            Workbook wb = new Workbook(Address);// 原始excel路径



            FileOutputStream fileOS = new FileOutputStream(pdfFile);



            wb.save(fileOS, SaveFormat.PDF);



            fileOS.close();



        } catch (Exception e) {



            e.printStackTrace();



        }



    }



 



    public static boolean getLicense() {



        boolean result = false;



        try {



            InputStream is =



                    ExcelToPdfUtils.class



                            .getClassLoader()



                            .getResourceAsStream(



                                    "license.xml"); //



            // license.xml这个文件你放在静态文件资源目录下就行了



            License aposeLic = new License();



            aposeLic.setLicense(is);



            result = true;



        } catch (Exception e) {



            e.printStackTrace();



        }



        return result;



    }



}
```

### 2.3 ppt转pdf实现

```java
package com.ruoyi.common.utils.file;



 



 



import com.aspose.slides.License;



import com.aspose.slides.Presentation;



import com.aspose.slides.SaveFormat;



 



import java.io.File;



import java.io.FileOutputStream;



import java.io.InputStream;



 



/**



 * ppt 转pdf  帮助类



 */



public class PptToPdfUtils {



 



    private static InputStream license;



 



    /**



     * 获取license



     *



     * @return



     */



    public static boolean getLicense() {



        boolean result = false;



        try {



            license = PptToPdfUtils.class.getClassLoader().getResourceAsStream("license.xml");// license路径



            License aposeLic = new License();



            aposeLic.setLicense(license);



            result = true;



        } catch (Exception e) {



            e.printStackTrace();



        }



        return result;



    }



 



 



    /**



     * ppt 转pdf 方法



     * @param Address ppt原路径



     * @param outPath pdf转出路径



     */



    public static void ppt2pdf(String Address,String outPath) {



        // 验证License



        if (!getLicense()) {



            return ;



        }



        try {



            //   long old = System.currentTimeMillis();



            File file = new File(outPath);// 输出pdf路径



            Presentation pres = new Presentation(Address);//输入ppt路径



            FileOutputStream fileOS = new FileOutputStream(file);



            pres.save(fileOS, SaveFormat.Pdf);



            fileOS.close();



        } catch (Exception e) {



            e.printStackTrace();



        }



    }



 



 



 



}
```

### 2.4 pdf转jpg、png图片帮助类

 需要导入maven架包

```xml
<dependencys> 



   <dependency>



         <groupId>com.sleepycat</groupId>



         <artifactId>je</artifactId>



         <version>5.0.73</version>



    </dependency>



   <dependency>



         <groupId>org.apache.pdfbox</groupId>



         <artifactId>pdfbox</artifactId>



         <version>2.0.8</version>



    </dependency>



</dependencys> 
package com.ruoyi.common.utils.file;



 



import org.apache.pdfbox.pdmodel.PDDocument;



import org.apache.pdfbox.pdmodel.PDPageTree;



import org.apache.pdfbox.rendering.PDFRenderer;



 



import javax.imageio.ImageIO;



import java.awt.image.BufferedImage;



import java.io.*;



import java.text.SimpleDateFormat;



import java.util.ArrayList;



import java.util.Date;



import java.util.List;



import java.util.Random;



 



/**



 * pdf 转图片 帮助类



 */



public class PdftoImageUtils {



 



    /**



     *  pdf 转图片方法



     * @param address pdf原文件地址



     * @param toImagepath  转换后图片存放地址



     * @return   图片地址集合



     * @throws Exception



     */



    public static List<String> pdfToImageFile(String address, String toImagepath) throws Exception {



        PDDocument doc = null;



        ByteArrayOutputStream os = null;



        InputStream stream = null;



        OutputStream out = null;



        ArrayList<String> strings = new ArrayList<>();



        try {



            // pdf路径



            stream = new FileInputStream(address);



            // 加载解析PDF文件



            doc = PDDocument.load(stream);



            PDFRenderer pdfRenderer = new PDFRenderer(doc);



            PDPageTree pages = doc.getPages();



            int pageCount = pages.getCount();



            for (int i = 0; i < pageCount; i++) {



                BufferedImage bim = pdfRenderer.renderImageWithDPI(i, 200);



                os = new ByteArrayOutputStream();



                ImageIO.write(bim, "jpg", os);



                byte[] dataList = os.toByteArray();



                //获取当前时间  保存图片规则



                Date date = new Date();



                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");//可以方便地修改日期格式



                String format = dateFormat.format(date).replace(":","/");



                int anInt = new Random().nextInt(1000);  //随机数



                String imageAddress=toImagepath+"/"+format+"/hello_" + anInt + ".jpg";



                strings.add(imageAddress);



                // jpg文件转出路径



                File file = new File(imageAddress);



                if (!file.getParentFile().exists()) {



                    // 不存在则创建父目录及子文件



                    file.getParentFile().mkdirs();



                    file.createNewFile();



                }



                out = new FileOutputStream(file);



                out.write(dataList);



            }



            return strings;



        } catch (Exception e) {



            e.printStackTrace();



            throw e;



        } finally {



            if (doc != null) doc.close();



            if (os != null) os.close();



            if (stream != null) stream.close();



            if (out != null) out.close();



        }



    }



}
```

鄙人才疏学浅，希望对你们有帮助，谢谢！ 