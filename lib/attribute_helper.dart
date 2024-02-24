import 'package:flutter/material.dart';
import 'package:robiko_shop/model/category_attribute.dart';

class AttributeHelper {
  Widget buildAttributeWidget(
    CategoryAttribute attribute,
    StateSetter setStateDialog,
    Map<int, String> attributeValues,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: attribute.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, // Change color if needed
              ),
              children: [
                if (attribute.required != false)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red, // Red color for the asterisk
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          _getField(attribute, setStateDialog, attributeValues),
        ],
      ),
    );
  }

  Widget _getField(
    CategoryAttribute attribute,
    StateSetter setStateDialog,
    Map<int, String> attributeValues,
  ) {
    switch (attribute.inputType) {
      case 'select':
        return _buildDropdown(
          attribute,
          setStateDialog,
          attributeValues,
        );
      case 'text-range':
      case 'text':
        return _buildTextField(
          attribute,
          setStateDialog,
          attributeValues,
        );
      case 'checkbox':
        return _buildCheckbox(
          attribute,
          setStateDialog,
          attributeValues,
        );
      default:
        return Container();
    }
  }

  Widget _buildDropdown(
    CategoryAttribute attribute,
    StateSetter setStateDialog,
    Map<int, String> attributeValues,
  ) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      value: attributeValues[attribute.id],
      // onChanged: (String? newValue) {
      //   setState(() {
      //     selectedValue = newValue;
      //   });
      // },
      onChanged: (String? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue;
          });
        }
      },
      items: attribute.options?.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    CategoryAttribute attribute,
    StateSetter setStateDialog,
    Map<int, String> attributeValues,
  ) {
    return TextFormField(
      onChanged: (String? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue;
          });
        }
      },
      initialValue: attributeValues[attribute.id],
      decoration: const InputDecoration(
        // labelText: attribute.displayName,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCheckbox(
    CategoryAttribute attribute,
    StateSetter setStateDialog,
    Map<int, String> attributeValues,
  ) {
    return CheckboxListTile(
      title: Text(attribute.displayName ?? ''),
      value: attributeValues[attribute.id] == 'true' ? true : false,
      onChanged: (bool? newValue) {
        if (newValue != null) {
          setStateDialog(() {
            attributeValues[attribute.id] = newValue.toString();
          });
        }
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
